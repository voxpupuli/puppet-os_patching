#!/opt/puppetlabs/puppet/bin/ruby

require 'rbconfig'
require 'open3'
require 'json'
require 'time'
require 'timeout'

# constant so available in methods. global variables are naughty in ruby land!
IS_WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

$stdout.sync = true

if IS_WINDOWS
  # windows
  # use ruby file logger
  require 'logger'
  log = Logger.new('C:/ProgramData/os_patching/os_patching_task.log', 'monthly')
  # set paths/commands for windows
  fact_generation_script = 'C:/ProgramData/os_patching/os_patching_fact_generation.ps1'
  fact_generation_cmd = "#{ENV['systemroot']}/system32/WindowsPowerShell/v1.0/powershell.exe -ExecutionPolicy RemoteSigned -file #{fact_generation_script}"
  @puppet_cmd = "#{ENV['programfiles']}/Puppet Labs/Puppet/bin/puppet"
  shutdown_cmd = 'shutdown /r /t 60 /c "Rebooting due to the installation of updates by os_patching" /d p:2:17'
else
  # not windows
  # create syslog logger
  require 'syslog/logger'
  log = Syslog::Logger.new 'os_patching'
  # set paths/commands for linux
  fact_generation_script = '/usr/local/bin/os_patching_fact_generation.sh'
  fact_generation_cmd = fact_generation_script
  @puppet_cmd = '/opt/puppetlabs/puppet/bin/puppet'
  shutdown_cmd = 'nohup /sbin/shutdown -r +1 2>/dev/null 1>/dev/null &'

  ENV['LC_ALL'] = 'C'
end

starttime = Time.now.iso8601
BUFFER_SIZE = 4096

# Function to write out the history file after patching
def history(dts, message, code, reboot, security, job)
  historyfile = if IS_WINDOWS
                  'C:/ProgramData/os_patching/run_history'
                else
                  '/var/cache/os_patching/run_history'
                end
  open(historyfile, 'a') do |f|
    f.puts "#{dts}|#{message}|#{code}|#{reboot}|#{security}|#{job}"
  end
end

def run_with_timeout(command, timeout)
  stdout = ''
  stderr = ''
  exit_code = nil
  wait_thr = nil

  begin
    Timeout.timeout(timeout) do
      Open3.popen3(*command) do |stdin, out, err, thread|
        wait_thr = thread
        stdin.close

        stdout = out.read
        stderr = err.read
        exit_code = wait_thr.value.exitstatus
      end
    end
  rescue Timeout::Error
    if wait_thr
      begin
        Process.kill('TERM', wait_thr.pid)
        sleep 2
        Process.kill('KILL', wait_thr.pid)
      rescue Errno::ESRCH
        nil
      end
    end

    err('403', 'os_patching/patching', "TIMEOUT AFTER #{timeout} seconds", Time.now.iso8601)
  end

  [exit_code, stdout, stderr]
end

# pending reboot detection function for windows
def pending_reboot_win
  # detect if a pending reboot is needed on windows
  # inputs: none
  # outputs: true or false based on whether a reboot is needed

  require 'base64'

  # multi-line string which is the PowerShell scriptblock to look up whether or not a pending reboot is needed
  # may want to convert this to ruby in the future
  # note all the escaped characters if attempting to edit this script block
  # " (double quote) is "\ (double quote backslash)
  # \ (backslash) is \\ (double backslash)
  pending_reboot_win_cmd = %{
      $ErrorActionPreference=\"stop\"
      $rebootPending = $false
      if (Get-ChildItem \"HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending\" -EA Ignore) { $rebootPending = $true }
      if (Get-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update\\RebootRequired\" -EA Ignore) { $rebootPending = $true }
      if (Get-ItemProperty \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\" -Name PendingFileRenameOperations -EA Ignore) { $rebootPending = $true }
      try {
          $util = [wmiclass]\"\\\\.\\root\\ccm\\clientsdk:CCM_ClientUtilities\"
          $status = $util.DetermineIfRebootPending()
          if (($null -ne $status) -and $status.RebootPending) {
              $rebootPending = $true
          }
      }
      catch {}
      $rebootPending
  }

  # encode to base64 as this is the easist way to pass a readable multi-line scriptblock to PowerShell externally
  encoded_cmd = Base64.strict_encode64(pending_reboot_win_cmd.encode('utf-16le'))

  # execute it and capture the result. this will return true or false in a string
  pending_reboot_stdout, _stderr, _status = Open3.capture3("powershell -NonInteractive -EncodedCommand #{encoded_cmd}")

  # return result
  if pending_reboot_stdout.split("\n").first.chomp == 'True'
    true
  else
    false
  end
end

def pending_reboot_linux(log, starttime)
  facts = gather_facts(log, starttime)

  # check for existence of /var/run/reboot-required file
  if facts['os']['family'] == 'RedHat'
    if File.file?('/usr/bin/needs-restarting')
      _output, _stderr, status = Open3.capture3('/usr/bin/needs-restarting -r')
      return true if status != 0
    else
      log.warn 'needs-restarting command not found, cannot determine if reboot is required'
      log.warn 'please install the dnf-utils package to enable this functionality'
    end

    return false
  end

  if File.file?('/var/run/reboot-required')
    true
  else
    false
  end
end

# Default output function
def output(returncode, reboot, security, message, packages_updated, debug, job_id, pinned_packages, starttime, log)
  endtime = Time.now.iso8601
  json = {
    :return           => returncode,
    :reboot           => reboot,
    :security         => security,
    :message          => message,
    :packages_updated => packages_updated,
    :debug            => debug,
    :job_id           => job_id,
    :pinned_packages  => pinned_packages,
    :start_time       => starttime,
    :end_time         => endtime,
    :duration         => Time.parse(endtime) - Time.parse(starttime),
  }

  json[:reboot_required] = pending_reboot_win if IS_WINDOWS
  json[:reboot_required] = pending_reboot_linux(log, starttime) unless IS_WINDOWS

  puts JSON.pretty_generate(json)
  history(starttime, message, returncode, reboot, security, job_id)
end

# Error output function
def err(code, kind, message, starttime)
  endtime = Time.now.iso8601
  exitcode = code.to_s.split.last
  json = {
    :_error =>
    {
      :msg        => "Task exited : #{exitcode}\n#{message}",
      :kind       => kind,
      :details    => {
        :exitcode => exitcode,
        :start_time => starttime,
        :end_time   => endtime,
      },
    },
  }

  puts JSON.pretty_generate(json)

  messagesplitfirst = message.split("\n").first
  messagesplitfirst ||= '' # set to empty string if nil
  shortmsg = messagesplitfirst.chomp

  history(starttime, shortmsg, exitcode, '', '', '')
  if IS_WINDOWS
    # windows
    # use ruby file logger
    require 'logger'
    log = Logger.new('C:/ProgramData/os_patching/os_patching_task.log', 'monthly')
  else
    # not windows
    # create syslog logger
    require 'syslog/logger'
    log = Syslog::Logger.new 'os_patching'
  end
  log.error "ERROR : #{kind} : #{exitcode} : #{message}"
  exit(exitcode.to_i)
end

# Figure out if we need to reboot
def reboot_required(family, release, reboot)
  # Do the easy stuff first
  if ['always', 'patched'].include?(reboot)
    true
  elsif reboot == 'never'
    false
  elsif family == 'RedHat' && File.file?('/usr/bin/needs-restarting') && reboot == 'smart'
    response = ''
    if release.to_i > 6
      _output, _stderr, status = Open3.capture3('/usr/bin/needs-restarting -r')
      response = if status != 0
                   true
                 else
                   false
                 end
    elsif release.to_i == 6
      # If needs restart returns processes on RHEL6, consider that the node
      # needs a reboot
      output, stderr, _status = Open3.capture3('/usr/bin/needs-restarting')
      response = if output.empty? && stderr.empty?
                   false
                 else
                   true
                 end
    else
      # Needs-restart doesn't exist before RHEL6
      response = true
    end
    response
  elsif family == 'Redhat'
    false
  elsif family == 'Debian' && File.file?('/var/run/reboot-required') && reboot == 'smart'
    true
  elsif family == 'Suse' && File.file?('/var/run/reboot-required') && reboot == 'smart'
    true
  elsif family == 'windows' && reboot == 'smart' && pending_reboot_win == true
    true
  else
    false
  end
end

def gather_facts(log, starttime)
  # Cache the facts
  log.debug 'Gathering facts'
  full_facts, stderr, status = Open3.capture3(@puppet_cmd, 'facts')
  err(status, 'os_patching/facter', stderr, starttime) if status != 0

  JSON.parse(full_facts)
end

# Parse input, get params in scope
params = nil
begin
  raw = STDIN.read
  params = JSON.parse(raw)
# rescue JSON::ParserError => e
rescue JSON::ParserError
  err(400, 'os_patching/input', "Invalid JSON received: '#{raw}'", starttime)
end

log.info 'os_patching run started'

# ensure node has been tagged with os_patching class by checking for fact generation script
log.debug 'Running os_patching fact refresh'
unless File.exist? fact_generation_script
  err(
    255,
    "os_patching/#{fact_generation_script}",
    "#{fact_generation_script} does not exist, declare os_patching and run Puppet first",
    starttime,
  )
end

# Cache the facts
facts = gather_facts(log, starttime)

if facts['os']
  os = facts['os']
  os_patching = facts['os_patching']
elsif facts['values']
  os = facts['values']['os']
  os_patching = facts['values']['os_patching']
else
  err(200, 'os_patching/facts', 'Could not find facts', starttime)
end

# Check we are on a supported platform
unless ['RedHat', 'Debian', 'Suse', 'windows'].include?(os['family'])
  err(200, 'os_patching/unsupported_os', 'Unsupported OS', starttime)
end

# Get the pinned packages
pinned_pkgs = os_patching['pinned_packages']

# Should we clean the cache prior to starting?
if params['clean_cache'] && params['clean_cache'] == true
  clean_cache = if os['family'] == 'RedHat'
                  'yum clean all'
                elsif os['family'] == 'Debian'
                  'apt-get clean'
                elsif os['family'] == 'Suse'
                  'zypper cc --all'
                end
  _fact_out, stderr, status = Open3.capture3(clean_cache)
  err(status, 'os_patching/clean_cache', stderr, starttime) if status != 0
  log.info 'Cache cleaned'
end

# Refresh the patching fact cache on non-windows systems
# Windows scans can take a long time, and we do one at the start of the os_patching_windows script anyway.
# No need to do yet another scan prior to this, it just wastes valuable time.
if os['family'] != 'windows'
  _fact_out, stderr, status = Open3.capture3(fact_generation_cmd)
  err(status, 'os_patching/fact_refresh', stderr, starttime) if status != 0
end

# Let's figure out the reboot gordian knot
#
# If the override is set, it doesn't matter that anything else is set to at this point
reboot_override = os_patching['reboot_override']
reboot_param = params['reboot']
reboot = ''
if reboot_override == 'always'
  reboot = 'always'
elsif ['never', false].include?(reboot_override)
  reboot = 'never'
elsif ['patched', true].include?(reboot_override)
  reboot = 'patched'
elsif reboot_override == 'smart'
  reboot = 'smart'
elsif reboot_override == 'default'
  if reboot_param
    if reboot_param == 'always'
      reboot = 'always'
    elsif ['never', false].include?(reboot_param)
      reboot = 'never'
    elsif ['patched', true].include?(reboot_param)
      reboot = 'patched'
    elsif reboot_param == 'smart'
      reboot = 'smart'
    else
      err('108', 'os_patching/params', 'Invalid parameter for reboot', starttime)
    end
  else
    reboot = 'never'
  end
else
  err(105, 'os_patching/reboot_override', 'Fact reboot_override invalid', starttime)
end

if reboot_override != reboot_param && reboot_override != 'default'
  log.info "Reboot override set to #{reboot_override}, reboot parameter set to #{reboot_param}.  Using '#{reboot_override}'"
end

log.info "Reboot after patching set to #{reboot}"

# Should we only apply security patches?
security_only = ''
if params['security_only']
  if params['security_only'] == true
    security_only = true
  elsif params['security_only'] == false
    security_only = false
  else
    err('109', 'os_patching/params', 'Invalid boolean to security_only parameter', starttime)
  end
else
  security_only = false
end
log.info "Apply only security patches set to #{security_only}"

# Have we had any yum parameter specified?
yum_params = if params['yum_params']
               params['yum_params']
             else
               ''
             end

# Make sure we're not doing something unsafe
if yum_params =~ %r{[\$\|\/;`&]}
  err('110', 'os_patching/yum_params', 'Unsafe content in yum_params', starttime)
end

# Have we had any dpkg parameter specified?
dpkg_params = if params['dpkg_params']
                params['dpkg_params']
              else
                ''
              end

# Make sure we're not doing something unsafe
if dpkg_params =~ %r{[\$\|\/;`&]}
  err('110', 'os_patching/dpkg_params', 'Unsafe content in dpkg_params', starttime)
end

# Have we had any zypper parameters specified?
zypper_params = if params['zypper_params']
                  params['zypper_params']
                else
                  ''
                end

# Make sure we're not doing something unsafe
if zypper_params =~ %r{[\$\|\/;`&]}
  err('110', 'os_patching/zypper_params', 'Unsafe content in zypper_params', starttime)
end
# Set the timeout for the patch run

if params['timeout'].positive?
  timeout = params['timeout']
else
  err('121', 'os_patching/timeout', "timeout set to #{timeout} seconds - invalid", starttime)
end

# Is the patching blocker flag set?
blocker = os_patching['blocked']
if blocker.to_s.chomp == 'true'
  # Patching is blocked, list the reasons and error
  # need to error as it SHOULDN'T ever happen if you
  # use the right workflow through tasks.
  log.error 'Patching blocked, not continuing'
  block_reason = os_patching['blocker_reasons']
  err(100, 'os_patching/blocked', "Patching blocked #{block_reason}", starttime)
end

# Should we look at security or all patches to determine if we need to patch?
# (requires RedHat subscription or Debian based distro... for now)
if security_only == true
  updatecount = os_patching['security_package_update_count']
  securityflag = '--security'
else
  updatecount = os_patching['package_update_count']
  securityflag = ''
end

# Get pre_patching_command
pre_patching_command = if os_patching['pre_patching_command']
                         os_patching['pre_patching_command']
                       else
                         ''
                       end

if File.exist?(pre_patching_command)
  if File.executable?(pre_patching_command)
    log.info 'Running pre_patching_command : #{pre_patching_command}'
    _fact_out, stderr, status = Open3.capture3(pre_patching_command)
    err(status, 'os_patching/pre_patching_command', "Pre-patching-command failed: #{stderr}", starttime) if status != 0
    log.info 'Finished pre_patching_command : #{pre_patching_command}'
  else
    err(210, 'os_patching/pre_patching_command', "Pre patching command not executable #{pre_patching_command}", starttime)
  end
elsif pre_patching_command != ''
  err(200, 'os_patching/pre_patching_command', "Pre patching command not found #{pre_patching_command}", starttime)
end

# There are no updates available, exit cleanly rebooting if the override flag is set
if updatecount.zero?
  if reboot == 'always'
    log.error 'Rebooting'
    output('Success', reboot, security_only, 'No patches to apply, reboot triggered', '', '', '', pinned_pkgs, starttime, log)
    $stdout.flush
    log.info 'No patches to apply, rebooting as requested'
    p1 = if IS_WINDOWS
           spawn(shutdown_cmd)
         else
           fork { system(shutdown_cmd) }
         end
    Process.detach(p1)
  else
    output('Success', reboot, security_only, 'No patches to apply', '', '', '', pinned_pkgs, starttime, log)
    log.info 'No patches to apply, exiting'
  end
  exit(0)
end

# Run the patching on the appropriate platforms
###############################################################################

if os['family'] == 'RedHat'
  log.info 'Running dnf upgrade'
  log.debug "Timeout value set to : #{timeout}"

  dnf_exitcode, dnf_output, dnf_error = run_with_timeout("dnf #{yum_params} #{securityflag} upgrade -y", timeout)

  err(dnf_exitcode, 'os_patching/dnf', "dnf upgrade returned non-zero (#{dnf_exitcode}) : #{dnf_output}\n#{dnf_error}", starttime) if dnf_exitcode != 0

  # Capture the dnf job ID
  log.info 'Getting dnf job ID'
  job_id = nil
  job_date = nil

  dnf_history, stderr, status = Open3.capture3('dnf history')
  err(status, 'os_patching/dnf', stderr, starttime) if status != 0

  dnf_history.split("\n").each do |line|
    # get `dnf history`,  which look like this :
    #
    # ID | Command line                         | Date and time    | Action(s)      | Altered
    # ----------------------------------------------------------------------------------------
    # 12 | upgrade -y                           | 2026-03-26 11:24 | Upgrade        |    1
    # 11 | downgrade openvox-agent-8.24.2-1.el8 | 2026-03-26 11:22 | Downgrade      |    1
    #
    # Search for the first line with "upgrade -y" which should be our patching run, and pull out the job ID and date from that line.
    #
    next unless line.include?('upgrade -y')

    # split the line into fields and pull out the job ID and date.
    # The fields are separated by '|' characters, but there may be multiple spaces around them,
    # so we split on '|' and then strip whitespace from the resulting fields.
    fields = line.split('|').map(&:strip)
    job_id = fields[0]
    job_date = fields[2]

    break
  end

  log.debug "Captured dnf job ID : #{job_id}"
  log.debug "Captured dnf job date : #{job_date}"

  # Fail if we didn't capture a job ID
  err(1, 'os_patching/dnf', 'dnf job ID not found', starttime) if job_id.nil?

  # Fail if we didn't capture a job time
  err(1, 'os_patching/dnf', 'dnf job time not found', starttime) if job_date.nil?

  # Check that the first dnf history entry was after the dnf_start time
  # we captured.  Append ':59' to the date as dnf history only gives the
  # minute and if dnf bails, it will usually be pretty quick
  parsed_end = Time.parse(job_date + ':59').iso8601
  err(1, 'os_patching/dnf', 'DNF did not appear to run', starttime) if parsed_end < starttime

  # Capture the dnf return code
  log.debug "Getting dnf return code for job #{job_id}"

  # Example output of `dnf history info <job_id>` :
  #
  # Transaction ID : 12
  # Begin time     : Thu Mar 26 11:24:18 2026
  # Begin rpmdb    : 485:f7aac331cf34d853f41f365d90ebec3de52f633e
  # End time       : Thu Mar 26 11:24:24 2026 (6 seconds)
  # End rpmdb      : 485:6cecf20abc141842a1fc3d31e6cfb72a5588e76c
  # User           : root <root>
  # Return-Code    : Success
  # Releasever     : 8
  # Command Line   : upgrade -y
  # Comment        :
  # Packages Altered:
  #     Upgrade  openvox-agent-8.25.0-1.el8.x86_64 @openvox8
  #     Upgraded openvox-agent-8.24.2-1.el8.x86_64 @@System
  #
  job_status, stderr, status = Open3.capture3("dnf history info #{job_id}")
  dnf_return = nil

  err(status, 'os_patching/dnf', stderr, starttime) if status != 0

  job_status.split("\n").each do |line|
    next unless line.start_with?('Return-Code')

    # Split the line into fields and pull out the return code.
    # The fields are separated by ':' characters, but there may be multiple spaces around them,
    # so we split on ':' and then strip whitespace from the resulting fields.
    # There might also be multiple colons in the return code if there is an error,
    # so we limit the split to 2 fields to ensure we capture the whole return code.
    dnf_return = line.split(':', 2).last.strip

    break
  end

  err(status, 'os_patching/dnf', 'dnf return code not found', starttime) if dnf_return.nil?

  pkg_hash = {}
  # Pull out the updated package list from dnf history
  log.debug "Getting updated package list for job #{job_id}"

  updated_packages, stderr, status = Open3.capture3("dnf history info #{job_id}")
  err(status, 'os_patching/dnf', stderr, starttime) if status != 0

  updated_packages.split("\n").each do |line|
    next unless line.strip.start_with?('Erased', 'Install', 'Removed', 'Updated', 'Upgraded')

    # Split the line into fields and pull out the action and package name.
    # The fields are separated by spaces, but there may be multiple spaces around them,
    # so we split on spaces and then strip whitespace from the resulting fields
    action, pkg_name, _source = line.split.map(&:strip)
    pkg_hash[pkg_name] = action
  end

  output(dnf_return, reboot, security_only, 'Patching complete', pkg_hash, job_status.split("\n"), job_id, pinned_pkgs, starttime, log)
  log.info 'Patching complete'
elsif os['family'] == 'Debian'
  log.info 'Running apt'
  log.debug "Timeout value set to : #{timeout}"

  # Are we doing security only patching?
  if security_only == true
    pkg_list = os_patching['security_package_updates']
    apt_mode = 'install ' + pkg_list.join(' ')
  else
    pkg_list = os_patching['package_updates']
    apt_mode = 'dist-upgrade'
  end

  # Do the patching
  log.debug "Running apt #{apt_mode}"
  deb_front = 'DEBIAN_FRONTEND=noninteractive'
  deb_opts = '-o Apt::Get::Purge=false -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef --no-install-recommends'
  # apt_std_out, stderr, status = Open3.capture3("#{deb_front} apt-get #{dpkg_params} -y #{deb_opts} #{apt_mode}")
  apt_exitcode, apt_out, apt_err = run_with_timeout("#{deb_front} apt-get #{dpkg_params} -y #{deb_opts} #{apt_mode}", timeout)

  log.debug "apt output : #{apt_out}"
  log.debug "apt error output : #{apt_err}"
  log.debug "apt exit status : #{apt_exitcode}"

  err(apt_exitcode, 'os_patching/apt', "Error: #{apt_err}", starttime) if apt_exitcode != 0

  output('Success', reboot, security_only, 'Patching complete', pkg_list, apt_out.split("\n"), '', pinned_pkgs, starttime, log)
  log.info 'Patching complete'
elsif os['family'] == 'windows'
  # we're on windows

  # Are we doing security only patching?
  security_arg = if security_only == true
                   '-SecurityOnly'
                 else
                   ''
                 end

  # build patching command
  powershell_cmd = "#{ENV['systemroot']}/system32/WindowsPowerShell/v1.0/powershell.exe -NonInteractive -ExecutionPolicy RemoteSigned -File"
  win_patching_cmd = "#{powershell_cmd} #{params['_installdir']}/os_patching/files/os_patching_windows.ps1 #{security_arg} -Timeout #{timeout}"

  log.info 'Running patching powershell script'

  # run the windows patching script
  win_std_out, stderr, status = Open3.capture3(win_patching_cmd)

  # report an error if non-zero exit status
  err(status, 'os_patching/win', stderr, starttime) if status != 0 || stderr != ''

  # get output file location
  output_file = ''
  win_std_out.split("\n").each do |line|
    matchdata = line.to_s.match(/^##output file is.*/im)
    next unless matchdata
    output_file = matchdata.to_s.sub(/^##output file is /i, '')
    break
  end

  if output_file != 'not applicable'
    # parse output file as json
    output_data = JSON.parse(File.read(output_file))

    # delete output file as it's no longer needed
    File.delete(output_file)

    # get update titles to return as result

    if output_data.is_a?(Array)
      # for multiple updates
      update_titles = []
      output_data.each do |item|
        update_titles.push(item['Title'])
      end
    else
      # for a single update... it happens!
      update_titles = output_data['Title']
    end

  else
    update_titles = ''
  end

  # output results
  # def output(returncode, reboot, security, message, packages_updated, debug, job_id, pinned_packages, starttime)
  output('Success', reboot, security_only, 'Patching complete', update_titles, win_std_out.split("\n"), '', '', starttime, log)
elsif os['family'] == 'Suse'
  zypper_required_params = '--non-interactive --no-abbrev --quiet'
  zypper_cmd_params = '--auto-agree-with-licenses'
  if os['release']['major'].to_i > 11
    zypper_cmd_params = "#{zypper_cmd_params} --replacefiles"
  end
  pkg_list = []
  if security_only == true
    pkg_list = os_patching['security_package_updates']
    log.info 'Running zypper patch'
    zypper_exitcode, zypper_output, zypper_error = run_with_timeout("zypper #{zypper_required_params} #{zypper_params} patch -g security #{zypper_cmd_params}", timeout)
    err(zypper_exitcode, 'os_patching/zypper', "zypper patch returned non-zero (#{zypper_exitcode}) : #{zypper_output}\n#{zypper_error}", starttime) if zypper_exitcode != 0
  else
    pkg_list = os_patching['package_updates']
    log.info 'Running zypper update'
    zypper_exitcode, zypper_output, zypper_error = run_with_timeout("zypper #{zypper_required_params} #{zypper_params} update -t package #{zypper_cmd_params}", timeout)
    err(zypper_exitcode, 'os_patching/zypper', "zypper update returned non-zero (#{zypper_exitcode}) : #{zypper_output}\n#{zypper_error}", starttime) if zypper_exitcode != 0
  end
  output('Success', reboot, security_only, 'Patching complete', pkg_list, zypper_output.split("\n"), '', pinned_pkgs, starttime, log)
  log.info 'Patching complete'
  log.debug "Timeout value set to : #{timeout}"
else
  # Only works on Redhat, Debian, Suse, and Windows at the moment
  log.error 'Unsupported OS - exiting'
  err(200, 'os_patching/unsupported_os', 'Unsupported OS', starttime)
end

# Refresh the facts now that we've patched - for non-windows systems
# Windows scans can take an eternity after a patch run prior to being reboot (30+ minutes in a lab on 2008 versions..)
# Best not to delay the whole patching process here.
# Note that the fact refresh (which includes a scan) runs on system startup anyway - see os_patching puppet class
if os['family'] != 'windows'
  log.info 'Running os_patching fact refresh'
  _fact_out, stderr, status = Open3.capture3(fact_generation_cmd)
  err(status, 'os_patching/fact', stderr, starttime) if status != 0
end

# Reboot if the task has been told to and there is a requirement OR if reboot_override is set to true
needs_reboot = reboot_required(os['family'], os['release']['major'], reboot)
log.info "reboot_required returning #{needs_reboot}"
if needs_reboot == true
  log.info 'Rebooting'
  p1 = if IS_WINDOWS
         spawn(shutdown_cmd)
       else
         fork { system(shutdown_cmd) }
       end
  Process.detach(p1)
end
log.info 'os_patching run complete'
exit 0
