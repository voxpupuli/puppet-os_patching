# @summary This manifest sets up a script and cron job to populate
#   the `os_patching` fact.
#
# @param puppet_binary [String]
#   Location of the Puppet binary
#
# @param patch_data_owner [String]
#   User name for the owner of the patch data
#
# @param patch_data_group [String]
#   Group name for the owner of the patch data
#
# @param patch_cron_user [String]
#   User who runs the cron job
#
# @param manage_yum_utils [Boolean]
#   Should the yum_utils/dnf_utils package be managed by this module on RedHat family nodes?
#   If `true`, use the parameter `yum_utils` to determine how it should be manged
#
# @param block_patching_on_warnings [Boolean]
#   If there are warnings present in the os_patching fact, should the patching task run?
#   If `true` the run will abort and take no action
#   If `false` the run will continue and attempt to patch (default)
#
# @param yum_utils
#   If managed, what should the yum_utils package set to?
#
# @param fact_upload [Boolean]
#   Should `puppet fact upload` be run after any changes to the fact cache files?
#
# @param apt_autoremove [Boolean]
#   Should `apt-get autoremove` be run during reboot?
#
# @param manage_delta_rpm [Boolean]
#   Should the deltarpm package be managed by this module on RedHat family nodes?
#   If `true`, use the parameter `delta_rpm` to determine how it should be manged
#
# @param delta_rpm
#   If managed, what should the delta_rpm package set to?
#
# @param manage_yum_plugin_security [Boolean]
#   Should the yum_plugin_security package be managed by this module on RedHat family nodes?
#   If `true`, use the parameter `yum_plugin_security` to determine how it should be manged
#
# @param yum_plugin_security
#   If managed, what should the yum_plugin_security package set to?
#
# @param reboot_override
#   Controls on a node level if a reboot should/should not be done after patching.
#   This overrides the setting in the task
#
# @option blackout_windows [String] :title
#   Name of the blackout window
#
# @option blackout_windows [String] :start
#   Start of the blackout window (ISO8601 format)
#
# @option blackout_windows [String] :end
#   End of the blackout window (ISO8601 format)
#
# @param patch_window [String]
#   A freeform text entry used to allocate a node to a specific patch window (Optional)
#
# @param blackout_windows [Hash]
#   Hash of start/end blackout dates+times (Optional)
#
# @param pre_patching_command [Stdlib::AbsolutePath]
#   The full path of the command to run prior to running patching.  Can be used to
#   run customised workflows such as gracefully shutting down applications.  The entry
#   must be a single absolute filename with no arguments or parameters.
#
# @param patch_cron_hour
#   The hour(s) for the cron job to run (defaults to absent, which means '*' in cron)
#
# @param patch_cron_month
#   The month(s) for the cron job to run (defaults to absent, which means '*' in cron)
#
# @param patch_cron_monthday
#   The monthday(s) for the cron job to run (defaults to absent, which means '*' in cron)
#
# @param patch_cron_weekday
#   The weekday(s) for the cron job to run (defaults to absent, which means '*' in cron)
#
# @param patch_cron_min
#   The min(s) for the cron job to run (defaults to a random number between 0 and 59)
#
# @param windows_update_hour
#   Control the hour on which windows nodes check for updates
#
# @param windows_update_interval_mins
#   Control how often windows updates for updates
#
# @param fact_mode
#   Mode to set on fact command file
#
# @param ensure
#   `present` to install scripts, cronjobs, files, etc, `absent` to cleanup a system that previously hosted us
#
# @example assign node to 'Week3' patching window, force a reboot and create a blackout window for the end of the year
#   class { 'os_patching':
#     patch_window     => 'Week3',
#     reboot_override  => 'always',
#     blackout_windows => {
#       'End of year change freeze' => {
#         'start' => '2018-12-15T00:00:00+10:00',
#         'end'   => '2019-01-15T23:59:59+10:00',
#       },
#     },
#   }
#
# @example An example profile to setup patching, sourcing blackout windows from hiera
#   class profiles::soe::patching (
#     $patch_window     = undef,
#     $blackout_windows = undef,
#     $reboot_override  = undef,
#   ){
#     # Pull any blackout windows out of hiera
#     $hiera_blackout_windows = lookup('profiles::soe::patching::blackout_windows',Hash,hash,{})
#
#     # Merge the blackout windows from the parameter and hiera
#     $full_blackout_windows = $hiera_blackout_windows + $blackout_windows
#
#     # Call the os_patching class to set everything up
#     class { 'os_patching':
#       patch_window     => $patch_window,
#       reboot_override  => $reboot_override,
#       blackout_windows => $full_blackout_windows,
#     }
#   }
#
# @example JSON hash to specify a change freeze from 2018-12-15 to 2019-01-15
#   {"End of year change freeze": {"start": "2018-12-15T00:00:00+10:00", "end": "2019-01-15T23:59:59+10:00"}}
#
# @example Run patching on the node `centos.example.com` using the smart reboot option
#   puppet task run os_patching::patch_server --params '{"reboot": "smart"}' --targets centos.example.com
#
# @example Remove from a managed system
#   class { 'os_patching':
#     ensure => absent,
#   }
class os_patching (
  Optional[Variant[Boolean, Enum['always', 'never', 'patched', 'smart', 'default']]] $reboot_override,
  Optional[Stdlib::Absolutepath] $pre_patching_command,
  Stdlib::Absolutepath $puppet_binary,
  String $patch_data_owner,
  String $patch_data_group,
  String $patch_cron_user,
  Boolean $manage_yum_utils,
  Boolean $manage_delta_rpm,
  Boolean $manage_yum_plugin_security,
  Boolean $fact_upload,
  Boolean $block_patching_on_warnings,
  Boolean $apt_autoremove,
  Integer[0,23] $windows_update_hour,
  Integer $windows_update_interval_mins,
  Stdlib::Filemode $fact_mode,
  Enum['installed', 'absent', 'purged', 'held', 'latest'] $yum_utils,
  Enum['installed', 'absent', 'purged', 'held', 'latest'] $delta_rpm,
  Enum['installed', 'absent', 'purged', 'held', 'latest'] $yum_plugin_security,
  Enum['present', 'absent'] $ensure,
  Variant[Enum['absent'], Integer[0,23]] $patch_cron_hour,
  Variant[Enum['absent'], Integer[1,12]] $patch_cron_month,
  Variant[Enum['absent'], Integer[1,31]] $patch_cron_monthday,
  Variant[Enum['absent'], Integer[0,7]] $patch_cron_weekday,
  Integer[0,59] $patch_cron_min = fqdn_rand(59),
  Optional[String] $patch_window = undef,
  Optional[Hash] $blackout_windows = undef,
) {
  # None tunable
  $cache_dir = lookup('os_patching::cache_dir',Stdlib::Absolutepath,first,undef)
  $fact_dir = lookup('os_patching::fact_dir',Stdlib::Absolutepath,first,undef)
  $fact_file = lookup('os_patching::fact_file',String,first,undef)

  $fact_exec = $ensure ? {
    'present' => 'os_patching::exec::fact',
    default   => undef,
  }

  case $facts['kernel'] {
    'FreeBSD', 'Linux': {
      File {
        owner => $patch_data_owner,
        group => $patch_data_group,
        mode  => '0644',
      }
    }
    'windows': {
    }
    default: { fail("Unsupported OS : ${facts['kernel']}") }
  }

  # calculate full path for fact command/script
  $fact_cmd = "${fact_dir}/${fact_file}"

  $fact_upload_exec = $ensure ? {
    'present' => 'os_patching::exec::fact_upload',
    default   => undef
  }

  $ensure_file = $ensure ? {
    'present' => 'file',
    default   => 'absent',
  }

  $ensure_dir = $ensure ? {
    'present' => 'directory',
    default   => 'absent',
  }

  if ($patch_window and $patch_window !~ /[A-Za-z0-9\-_ ]+/ ) {
    fail('The patch window can only contain alphanumerics, space, underscore and dash')
  }

  file { $cache_dir:
    ensure => $ensure_dir,
    force  => true,
  }

  file { $fact_cmd:
    ensure => $ensure_file,
    mode   => $fact_mode,
    source => "puppet:///modules/${module_name}/${fact_file}",
    notify => Exec[$fact_exec],
  }

  $autoremove_ensure = $apt_autoremove ? {
    true    => 'present',
    default => 'absent'
  }

  $pre_patching_command_ensure = ($ensure == 'present' and $pre_patching_command ) ? {
    true    => 'file',
    default => 'absent'
  }

  $patch_window_ensure = ($ensure == 'present' and $patch_window ) ? {
    true    => 'file',
    default => 'absent'
  }

  $block_patching_ensure = ($ensure == 'present' and $block_patching_on_warnings ) ? {
    true    => 'file',
    default => 'absent'
  }

  file { "${cache_dir}/patch_window":
    ensure  => $patch_window_ensure,
    content => $patch_window,
  }

  file { "${cache_dir}/pre_patching_command":
    ensure  => $pre_patching_command_ensure,
    content => $pre_patching_command,
  }

  file { "${cache_dir}/block_patching_on_warnings":
    ensure => $block_patching_ensure,
    notify => Exec[$fact_exec],
  }

  $reboot_override_ensure = ($ensure == 'present' and $reboot_override) ? {
    true    => 'file',
    default => 'absent',
  }

  case $reboot_override {
    true: { $reboot_override_value = 'always' }
    false: { $reboot_override_value = 'never' }
    default: { $reboot_override_value = $reboot_override }
  }

  file { "${cache_dir}/reboot_override":
    ensure  => $reboot_override_ensure,
    content => $reboot_override_value,
  }

  if ($blackout_windows) {
    # Validate the information in the blackout_windows hash
    $blackout_windows.each | String $key, Hash $value | {
      if ( $key !~ /^[A-Za-z0-9_ ]+$/ ) {
        fail('Blackout description can only contain alphanumerics, space and underscore')
      }
      if ( $value['start'] !~ /^\d{,5}-\d{1,2}-\d{1,2}T\d{,2}:\d{,2}:\d{,2}[-\+]\d{,2}:\d{,2}$/ ) {
        fail('Blackout start time must be in ISO 8601 format (YYYY-MM-DDTmm:hh:ss[-+]hh:mm)')
      }
      if ( $value['end'] !~ /^\d{,5}-\d{1,2}-\d{1,2}T\d{,2}:\d{,2}:\d{,2}[-\+]\d{,2}:\d{,2}$/ ) {
        fail('Blackout end time must be in ISO 8601 format  (YYYY-MM-DDTmm:hh:ss[-+]hh:mm)')
      }
      if ( $value['start'] > $value['end'] ) {
        fail('Blackout end time must after the start time')
      }
    }
  }

  $blackout_windows_ensure = ($ensure == 'present' and $blackout_windows) ? {
    true    => 'file',
    default => 'absent'
  }

  file { "${cache_dir}/blackout_windows":
    ensure  => $blackout_windows_ensure,
    content => epp("${module_name}/blackout_windows.epp", {
        'blackout_windows' => pick($blackout_windows, {}),
    }),
    require => File[$cache_dir],
  }

  if $fact_upload_exec and $fact_upload {
    exec { $fact_upload_exec:
      command     => "\"${puppet_binary}\" facts upload",
      path        => ['/opt/puppetlabs/bin/', '/usr/bin','/bin','/sbin','/usr/local/bin'],
      refreshonly => true,
      subscribe   => File[
        $fact_cmd,
        $cache_dir,
        "${cache_dir}/patch_window",
        "${cache_dir}/reboot_override",
        "${cache_dir}/blackout_windows",
      ],
    }
  }

  case $facts['kernel'] {
    'FreeBSD', 'Linux': {
      if ( $facts['os']['family'] == 'RedHat' and $manage_yum_utils) {
        if ( Integer($facts['os']['release']['major']) < 8) {
          package { 'yum-utils':
            ensure => $yum_utils,
          }
        } else {
          package { 'dnf-utils':
            ensure => $yum_utils,
          }
        }
      }

      if ( $facts['os']['family'] == 'RedHat' and $manage_delta_rpm) {
        if ( Integer($facts['os']['release']['major']) < 8 or $facts['os']['name'] == 'Fedora') {
          package { 'deltarpm':
            ensure => $delta_rpm,
          }
        }
        else {
          package { 'drpm':
            ensure => $delta_rpm,
          }
        }
      }

      if ( $facts['os']['family'] == 'RedHat' and $manage_yum_plugin_security and Integer($facts['os']['release']['major']) < 8 ) {
        package { 'yum-plugin-security':
          ensure => $yum_plugin_security,
        }
      }

      if $fact_exec {
        exec { $fact_exec:
          command     => $fact_cmd,
          user        => $patch_data_owner,
          group       => $patch_data_group,
          refreshonly => true,
          require     => [
            File[$fact_cmd],
            File["${cache_dir}/reboot_override"]
          ],
        }
      }

      cron { 'Cache patching data':
        ensure   => $ensure,
        command  => "${fact_cmd} >/dev/null 2>/dev/null",
        user     => $patch_cron_user,
        hour     => $patch_cron_hour,
        minute   => $patch_cron_min,
        month    => $patch_cron_month,
        monthday => $patch_cron_monthday,
        weekday  => $patch_cron_weekday,
        require  => File[$fact_cmd],
      }

      cron { 'Cache patching data at reboot':
        ensure  => $ensure,
        command => "${fact_cmd} >/dev/null 2>/dev/null",
        user    => $patch_cron_user,
        special => 'reboot',
        require => File[$fact_cmd],
      }

      if $facts['os']['family'] == 'Debian' {
        cron { 'Run apt autoremove on reboot':
          ensure  => $autoremove_ensure,
          command => 'apt-get -y autoremove',
          user    => $patch_cron_user,
          special => 'reboot',
        }
      }
    }
    'windows': {
      if $fact_exec {
        exec { $fact_exec:
          path        => 'C:/Windows/System32/WindowsPowerShell/v1.0',
          timeout     => 900,
          refreshonly => true,
          command     => "powershell -executionpolicy remotesigned -file ${fact_cmd}",
        }
      }

      scheduled_task { 'os_patching fact generation':
        ensure    => $ensure,
        enabled   => true,
        command   => "${facts['os']['windows']['system32']}/WindowsPowerShell/v1.0/powershell.exe",
        arguments => "-NonInteractive -ExecutionPolicy RemoteSigned -File ${fact_cmd}",
        user      => 'SYSTEM',
        trigger   => [
          {
            schedule         => daily,
            start_time       => "${windows_update_hour}:${patch_cron_min}",
            minutes_interval => $windows_update_interval_mins,
          },
          {
            schedule => 'boot',
          },
        ],
        require   => File[$fact_cmd],
      }
    }
    default: { fail('Unsupported OS') }
  }
}
