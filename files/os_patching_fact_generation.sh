#!/bin/sh
#
# Generate cache of patch data for consumption by Puppet custom facts.
#

PATH=/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:/bin:/sbin:/usr/bin:/usr/sbin:/bin:/usr/local/bin:/usr/local/sbin

LOCKFILE=/var/run/os_patching_fact_generation.lock

trap "{ rm -f $LOCKFILE ; exit 255; }" 2 3 15

if [ -f "$LOCKFILE" ]
then
  ps -fp $(cat "$LOCKFILE") >/dev/null
  if [ $? -eq 0 ]
  then
    PID=$(cat "$LOCKFILE")
    echo "Locked, by pid ${PID} exiting" >&2
    exit 0
  else
    echo "$$" > $LOCKFILE
  fi
else
  echo "$$" > $LOCKFILE
fi

if [ $(puppet --version|cut -d. -f1) -gt 6 ]; then
  OSFAMILY=$(puppet facts show --render-as s osfamily | cut -d\" -f4)
  VARDIR=$(puppet config print vardir)
  OSRELEASEMAJOR=$(puppet facts show --render-as s os.release.major | cut -d\" -f4)
else
  OSFAMILY=$(facter osfamily)
  VARDIR=$(facter -p puppet_vardir)
  OSRELEASEMAJOR=$(facter os.release.major)
fi

case $OSFAMILY in
  RedHat)
    # Sometimes yum check-update will output extra info like this:
    # ---
    # Security: kernel-3.14.6-200.fc20.x86_64 is an installed security update
    # Security: kernel-3.14.2-200.fc20.x86_64 is the currently running version
    # ---
    # We need to filter those out as they screw up the package listing
    PKGS=$(yum -q check-update 2>/dev/null| grep -E -v "^[Ss]ecurity:" | grep -oP '^.*?(?= )')
    PKGS=$(echo $PKGS | sed 's/Obsoleting.*//')
    SECPKGS=$(yum -q --security check-update 2>/dev/null| grep -E -v "^Security:" | grep -oP '^.*?(?= )')
    SECPKGS=$(echo $SECPKGS | sed 's/Obsoleting.*//')
    HELDPKGS=$([ -r /etc/yum/pluginconf.d/versionlock.list ] && awk -F':' '/:/ {print $2}' /etc/yum/pluginconf.d/versionlock.list | sed 's/-[0-9].*//')
  ;;
  Suse)
    PKGS=$(zypper --non-interactive --no-abbrev --quiet lu | grep '|' | grep -v '\sRepository' | awk -F'|' '/^[[:alnum:]]/ {print $3}' | sed 's/^\s*\|\s*$//')
    SECPKGS=$(zypper --non-interactive --no-abbrev --quiet lp -g security | grep '|' | grep -v '^Repository' | awk -F'|' '/^[[:alnum:]]/ {print $2}' | sed 's/^\s*\|\s*$//')
    HELDPKGS=$(zypper --non-interactive --no-abbrev --quiet ll | grep '|' | grep -v '^Repository' | awk -F'|' '/^[[:alnum:]]/ {print $2}' | sed 's/^\s*\|\s*$//')
  ;;
  Debian)
    apt update 2>/dev/null 1>/dev/null
    PKGS=$(apt upgrade -s 2>/dev/null | awk '$1 == "Inst" {print $2}')
    SECPKGS=$(apt upgrade -s 2>/dev/null | awk 'BEGIN {IGNORECASE = 1}; $1 == "Inst" && /Security/ {print $2}')
    HELDPKGS=$(dpkg --get-selections | awk '$2 == "hold" {print $1}')
  ;;
  FreeBSD)
    PKGS=$(pkg version -ql\< | awk '{print $1}')
    SECPKGS=$(pkg audit -qF)
    HELDPKGS=$(pkg lock -ql)
  ;;
  *)
    rm $LOCKFILE
    exit 1
  ;;
esac

DATADIR='/var/cache/os_patching'
UPDATEFILE="$DATADIR/package_updates"
SECUPDATEFILE="$DATADIR/security_package_updates"
OSHELDPKGFILE="$DATADIR/os_version_locked_packages"
CATHELDPKGFILE="$DATADIR/catalog_version_locked_packages"
MISMATCHHELDPKGFILE="$DATADIR/mismatched_version_locked_packages"
CATALOG="$VARDIR/client_data/catalog/$(puppet config print certname --section agent).json"

# Prefer AIO ruby if available, but fallback to system ruby otherwise.
if [ -x /opt/puppetlabs/puppet/bin/ruby ]
then
	RUBY=/opt/puppetlabs/puppet/bin/ruby
else
	RUBY=ruby
fi

if [ -f "${CATALOG}" ]
then
  VERSION_LOCK_FROM_CATALOG=$(cat $CATALOG | $RUBY -e "require 'json'; json_hash = JSON.parse(ARGF.read); json_hash['resources'].select { |r| r['type'] == 'Package' and r['parameters'] and r['parameters']['ensure'] and r['parameters']['ensure'].match /\d.+/ }.each do | m | puts m['title'] end")
else
	VERSION_LOCK_FROM_CATALOG=''
fi


if [ ! -d "${DATADIR}" ]
then
  logger -p error -t os_patching_fact_generation.sh "Can't find ${DATADIR}, exiting"
  rm $LOCKFILE
  exit 1
fi

cat /dev/null > ${UPDATEFILE}
for UPDATE in $PKGS
do
  echo "$UPDATE" >> ${UPDATEFILE}
done

cat /dev/null > ${SECUPDATEFILE}
for UPDATE in $SECPKGS
do
  echo "$UPDATE" >> ${SECUPDATEFILE}
done

cat /dev/null > ${OSHELDPKGFILE}
for HELD in $HELDPKGS
do
 echo "$HELD" >> ${OSHELDPKGFILE}
done

cat /dev/null > ${MISMATCHHELDPKGFILE}
cat /dev/null > ${CATHELDPKGFILE}
for CATHELD in $VERSION_LOCK_FROM_CATALOG
do
  if [ $(grep -E -c "^${CATHELD}$" ${OSHELDPKGFILE}) -eq 0 ]
	then
		echo "$CATHELD" >> ${MISMATCHHELDPKGFILE}
	fi
 echo "$CATHELD" >> ${CATHELDPKGFILE}
done

if [ -f '/usr/bin/needs-restarting' ]
then
  if [ $OSRELEASEMAJOR -gt 6 ]
  then
    /usr/bin/needs-restarting -r 2>/dev/null 1>/dev/null
    if [ $? -gt 0 ]
    then
      echo "true" > $DATADIR/reboot_required
    else
      echo "false" > $DATADIR/reboot_required
    fi
    /usr/bin/needs-restarting 2>/dev/null | grep -v 'Updating Subscription Management repositories' | sed 's/[[:space:]]*$//' >$DATADIR/apps_to_restart
  else
    /usr/bin/needs-restarting 2>/dev/null | grep -v 'Updating Subscription Management repositories' > $DATADIR/apps_to_restart
    if [ $? -gt 0 ]
    then
      echo "true" > $DATADIR/reboot_required
    else
      APPS_TO_RESTART=$(wc -l $DATADIR/apps_to_restart | awk '{print $1}')
      if [ $APPS_TO_RESTART -gt 0 ]
      then
        echo "true" > $DATADIR/reboot_required
      else
        echo "false" > $DATADIR/reboot_required
      fi
    fi
  fi
else
  touch $DATADIR/apps_to_restart
  touch $DATADIR/reboot_required
fi

if [ $OSFAMILY = 'Debian' ] || [ $OSFAMILY = 'Suse' ]
then
  if [ -f '/var/run/reboot-required' ]
  then
    echo "true" > $DATADIR/reboot_required
  else
    echo "false" > $DATADIR/reboot_required
  fi
  touch $DATADIR/apps_to_restart
fi

puppet facts upload 2>/dev/null 1>/dev/null
logger -p info -t os_patching_fact_generation.sh "patch data fact refreshed"

rm $LOCKFILE
exit 0
