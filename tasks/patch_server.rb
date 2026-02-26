#!/opt/puppetlabs/puppet/bin/ruby

require 'rbconfig'
require 'open3'
require 'json'
require 'time'
require 'timeout'

starttime = Time.now.iso8601

# constant so available in methods. global variables are naughty in ruby land!
IS_WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
BUFFER_SIZE = 4096
supported_families = ['RedHat', 'Debian', 'Suse', 'windows']

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

# Function to run a command with a timeout, and capture output without blocking
def run_with_timeout(command, timeout, tick)
  output = ''
  begin
    # Start task in another thread, which spawns a process
    stdin, stderrout, thread = Open3.popen2e(command)
    # Get the pid of the spawned process
    pid = thread[:pid]
    start = Time.now

    while (Time.now - start) < timeout && thread.alive?
      # Wait up to `tick` seconds for output/error data
      Kernel.select([stderrout], nil, nil, tick)
      # Try to read the data
      begin
        output << stderrout.read_nonblock(BUFFER_SIZE)
      rescue IO::WaitReadable
        # A read would block, so loop around for another select
        sleep 1
      rescue EOFError
        # Command has completed, not really an error...
        break
      end
    end
    # Give Ruby time to clean up the other thread
    sleep 1

    if thread.alive?
      # We need to kill the process, because killing the thread leaves
      # the process alive but detached, annoyingly enough.
      Process.kill('TERM', pid)
      err('403', 'os_patching/patching', "TIMEOUT AFTER #{timeout} seconds\n#{output}", start)
    end
  ensure
    stdin.close if stdin
    stderrout.close if stderrout
    status = thread.value.exitstatus
  end
  [status, output]
end

# Function to detect if a pending reboot is needed on windows.
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

# Function to detect if a pending reboot is needed on linux.
def pending_reboot_linux(log, starttime)
  facts = gather_facts(log, starttime)

  # check for existence of /var/run/reboot-required file
  if facts['os']['family'] == 'RedHat'
    if File.file?('/usr/bin/needs-restarting')
      _output, _stderr, status = Open3.capture3('/usr/bin/needs-restarting -r')
      return true unless status.success?
    else
      log.warn 'needs-restarting command not found, cannot determine if reboot is required'
      log.warn 'please install the yum-util/dnf-utils package to enable this functionality'
    end

    return false
  end

  if File.file?('/var/run/reboot-required')
    true
  else
    false
  end
end

# Function to output results in a consistent format for the task, and write to history
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
    :duration         => Time.parse(endtime) - Time.parse(starttime)
  }

  json[:reboot_required] = pending_reboot_win if IS_WINDOWS
  json[:reboot_required] = pending_reboot_linux(log, starttime) unless IS_WINDOWS

  puts JSON.pretty_generate(json)
  history(starttime, message, returncode, reboot, security, job_id)
end

# Function to output errors in a consistent format for the task, and write to history
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

# Function to determine if a reboot is required based on the OS family, release, and reboot setting
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
      response = if status.success?
                   false
                 else
                   true
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

# Function to gather facts, and handle any errors in doing so
def gather_facts(log, starttime)
  # Cache the facts
  log.debug 'Gathering facts'
  full_facts, stderr, status = Open3.capture3(@puppet_cmd, 'facts')
  err(status, 'os_patching/facter', stderr, starttime) unless status.success?

  JSON.parse(full_facts)
end

# Function to run patching on RHEL based systems
def patch_rhel(yum_params, securityflag, timeout, log, starttime, reboot, security_only, pinned_pkgs)
  log.info 'Running dnf upgrade'
  log.debug "Timeout value set to : #{timeout}"
  dnf_end = nil
  status, output = run_with_timeout("dnf #{yum_params} #{securityflag} upgrade -y", timeout, 2)
  err(status, 'os_patching/dnf', "dnf upgrade returned non-zero (#{status}) : #{output}", starttime) unless status.success?

  # Capture the dnf job ID
  log.info 'Getting dnf job ID'
  job = ''
  dnf_id, stderr, status = Open3.capture3('dnf history')
  err(status, 'os_patching/dnf', stderr, starttime) unless status.success?
  dnf_id.split("\n").each do |line|
    # Quite the regex.  This pulls out fields 1 & 3 from the first info line
    # from `dnf history`,  which look like this :
    # ID     | Login user               | Date and time    | 8< SNIP >8
    # ------------------------------------------------------ 8< SNIP >8
    #     69 | System <unset>           | 2018-09-17 17:18 | 8< SNIP >8
    matchdata = line.to_s.match(/^\s+(\d+)\s*\|\s*[\w\-<>,= ]*\|\s*([\d:\- ]*)/)
    next unless matchdata
    job = matchdata[1]
    dnf_end = matchdata[2]
    break
  end

  # Fail if we didn't capture a job ID
  err(1, 'os_patching/dnf', 'dnf job ID not found', starttime) if job.empty?

  # Fail if we didn't capture a job time
  err(1, 'os_patching/dnf', 'dnf job time not found', starttime) if dnf_end.empty?

  # Check that the first dnf history entry was after the dnf_start time
  # we captured.  Append ':59' to the date as dnf history only gives the
  # minute and if dnf bails, it will usually be pretty quick
  parsed_end = Time.parse(dnf_end + ':59').iso8601
  err(1, 'os_patching/dnf', 'dnf did not appear to run', starttime) if parsed_end < starttime

  # Capture the dnf return code
  log.debug "Getting dnf return code for job #{job}"
  dnf_status, stderr, status = Open3.capture3("dnf history info #{job}")
  dnf_return = ''
  err(status, 'os_patching/dnf', stderr, starttime) unless status.success?
  dnf_status.split("\n").each do |line|
    matchdata = line.match(/^Return-Code\s+:\s+(.*)$/)
    next unless matchdata
    dnf_return = matchdata[1]
    break
  end

  err(status, 'os_patching/dnf', 'dnf return code not found', starttime) if dnf_return.empty?

  pkg_hash = {}
  # Pull out the updated package list from dnf history
  log.debug "Getting updated package list for job #{job}"
  updated_packages, stderr, status = Open3.capture3("dnf history info #{job}")
  err(status, 'os_patching/dnf', stderr, starttime) unless status.success?
  updated_packages.split("\n").each do |line|
    matchdata = line.match(/^\s+(Installed|Install|Upgraded|Erased|Updated)\s+(\S+)\s/)
    next unless matchdata
    pkg_hash[matchdata[2]] = matchdata[1]
  end

  output(dnf_return, reboot, security_only, 'Patching complete', pkg_hash, output, job, pinned_pkgs, starttime, log)
end

# Function to run patching on debian based systems
def patch_debian(dpkg_params, timeout, log, starttime, reboot, security_only, pinned_pkgs)
  # Are we doing security only patching?
  apt_mode = ''
  pkg_list = []
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
  status, output = run_with_timeout("#{deb_front} apt-get #{dpkg_params} -y #{deb_opts} #{apt_mode}", timeout, 2)
  err(status, 'os_patching/apt', output, starttime) unless status.success?

  output('Success', reboot, security_only, 'Patching complete', pkg_list, output, '', pinned_pkgs, starttime, log)
end

# Function to run patching on windows based systems
def patch_windows(timeout, log, starttime, reboot, security_only)
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
  err(status, 'os_patching/win', stderr, starttime) unless status.success? || stderr.empty?

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
  log.info 'Patching complete'
end

# Function to run patching on SUSE based systems
def patch_suse(zypper_params, timeout, log, starttime, reboot, security_only, pinned_pkgs)
  zypper_required_params = '--non-interactive --no-abbrev --quiet'
  zypper_cmd_params = '--auto-agree-with-licenses'
  zypper_cmd_params = "#{zypper_cmd_params} --replacefiles" if os['release']['major'].to_i > 11

  pkg_list = []

  if security_only
    pkg_list = os_patching['security_package_updates']
    log.info 'Running zypper patch'
    status, output = run_with_timeout("zypper #{zypper_required_params} #{zypper_params} patch -g security #{zypper_cmd_params}", timeout, 2)
    err(status, 'os_patching/zypper', "zypper patch returned non-zero (#{status}) : #{output}", starttime) unless status.success?
  else
    pkg_list = os_patching['package_updates']
    log.info 'Running zypper update'
    status, output = run_with_timeout("zypper #{zypper_required_params} #{zypper_params} update -t package #{zypper_cmd_params}", timeout, 2)
    err(status, 'os_patching/zypper', "zypper update returned non-zero (#{status}) : #{output}", starttime) unless status.success?
  end

  output('Success', reboot, security_only, 'Patching complete', pkg_list, output, '', pinned_pkgs, starttime, log)
end

# Function to run any pre-patching command specified in the facts
def run_pre_patching_command(pre_patching_command, log, starttime)
  if File.exist?(pre_patching_command)
    if File.executable?(pre_patching_command)
      log.info "Running pre_patching_command : #{pre_patching_command}"
      _output, stderr, status = Open3.capture3(pre_patching_command)
      err(status, 'os_patching/pre_patching_command', "Pre-patching-command failed: #{stderr}", starttime) unless status.success?
      log.info "Finished pre_patching_command : #{pre_patching_command}"
    else
      err(210, 'os_patching/pre_patching_command', "Pre patching command not executable #{pre_patching_command}", starttime)
    end
  else
    err(200, 'os_patching/pre_patching_command', "Pre patching command not found #{pre_patching_command}", starttime)
  end
end

# Function to determine the reboot setting to use based on the reboot_override fact and the reboot parameter passed to the task
def determine_reboot(reboot_override, reboot_param, starttime)
  case reboot_override
  when 'always'
    'always'
  when 'never', false
    'never'
  when 'patched', true
    'patched'
  when 'smart'
    'smart'
  when 'default'
    if reboot_param
      case reboot_param
      when 'always'
        'always'
      when 'never', false
        'never'
      when 'patched', true
        'patched'
      when 'smart'
        'smart'
      else
        err('108', 'os_patching/params', "Invalid parameter for reboot: #{reboot_param}", starttime)
      end
    else
      'never'
    end
  else
    err(105, 'os_patching/reboot_override', "Fact reboot_override invalid: #{reboot_override}", starttime)
  end
end

# Function to refresh the facts on the system by running the fact generation script
def refresh_facts(log, fact_generation_cmd, starttime)
  log.info 'Running os_patching fact refresh'
  _fact_out, stderr, status = Open3.capture3(fact_generation_cmd)
  err(status, 'os_patching/fact_refresh', stderr, starttime) unless status.success?
end

# Function to clean the package manager cache based on the OS family
def clean_cache(os, starttime)
  clean_cache = if os['family'] == 'RedHat'
                  'dnf clean all'
                elsif os['family'] == 'Debian'
                  'apt-get clean'
                elsif os['family'] == 'Suse'
                  'zypper cc --all'
                end

  _output, stderr, status = Open3.capture3(clean_cache)
  err(status, 'os_patching/clean_cache', stderr, starttime) unless status.success?
end

# Function to perform the reboot action
def do_reboot(log, message, shutdown_cmd)
  log.info message
  p1 = IS_WINDOWS ? spawn(shutdown_cmd) : fork { system(shutdown_cmd) }
  Process.detach(p1)
end

###############################################################################
### Main execution starts here ################################################
###############################################################################

log.info 'os_patching run started'

# Parse input, get params in scope
params = nil

begin
  raw = $stdin.read
  params = JSON.parse(raw)
rescue JSON::ParserError
  err(400, 'os_patching/input', "Invalid JSON received: '#{raw}'", starttime)
end

# ensure node has been tagged with os_patching class by checking for fact generation script
log.debug 'Running os_patching fact refresh'
err(255, "os_patching/#{fact_generation_script}", "#{fact_generation_script} does not exist, declare os_patching and run Puppet first", starttime) unless File.exist? fact_generation_script

# Cache the facts
facts = gather_facts(log, starttime)

if facts.key?('os') && facts.key?('os_patching')
  os = facts['os']
  os_patching = facts['os_patching']
else
  err(200, 'os_patching/facts', 'Could not find facts', starttime)
end

# Check we are on a supported platform
err(200, 'os_patching/unsupported_os', "Unsupported OS: #{os['family']}", starttime) unless supported_families.include?(os['family'])

# Get the pinned packages
pinned_pkgs = os_patching['pinned_packages']

# Should we clean the cache prior to starting?
clean_cache(os, starttime) if params['clean_cache']
log.info 'Cache cleaned'

# Refresh the patching fact cache on non-windows systems
# Windows scans can take a long time, and we do one at the start of the os_patching_windows script anyway.
# No need to do yet another scan prior to this, it just wastes valuable time.
refresh_facts(log, fact_generation_cmd, starttime) unless os['family'] == 'windows'

# Let's figure out the reboot gordian knot
#
# If the override is set, it doesn't matter that anything else is set to at this point
reboot_override = os_patching['reboot_override']
reboot_param    = params['reboot']
reboot          = determine_reboot(reboot_override, reboot_param, log, starttime)

if reboot_override != reboot_param && reboot_override != 'default'
  log.info "Reboot override set to #{reboot_override}, reboot parameter set to #{reboot_param}. Using '#{reboot_override}'"
end

log.info "Reboot after patching set to #{reboot}"

# Should we only apply security patches?
security_only = params['security_only']
log.info 'Applying security patches only' if security_only == true

# Have we had any dnf parameter specified? And if so, are they safe?
yum_params = params['yum_params'] ? params['yum_params'] : nil
err('110', 'os_patching/yum_params', 'Unsafe content in yum_params', starttime) if yum_params =~ %r{[\$\|\/;`&]}

# Have we had any dpkg parameter specified? And if so, are they safe?
dpkg_params = params['dpkg_params'] ? params['dpkg_params'] : nil
err('110', 'os_patching/dpkg_params', 'Unsafe content in dpkg_params', starttime) if dpkg_params =~ %r{[\$\|\/;`&]}

# Have we had any zypper parameters specified? And if so, are they safe?
zypper_params = params['zypper_params'] ? params['zypper_params'] : nil
err('110', 'os_patching/zypper_params', 'Unsafe content in zypper_params', starttime) if zypper_params =~ %r{[\$\|\/;`&]}

# Set the timeout for the patch run
if params['timeout'].positive?
  timeout = params['timeout']
else
  err('121', 'os_patching/timeout', "timeout set to #{params['timeout']} seconds - invalid", starttime)
end

# Is the patching blocked flag set?
blocked = os_patching['blocked']

if blocked
  # Patching is blocked; list the reasons and exit with error
  # This condition should never occur if the proper workflow through tasks is followed
  log.error 'Patching blocked, not continuing'
  blocked_reasons = os_patching['blocked_reasons']
  err(100, 'os_patching/blocked', "Patching blocked #{blocked_reasons}", starttime)
end

# Should we look at security or all patches to determine if we need to patch?
# (requires RedHat subscription or Debian based distro... for now)
if security_only
  updatecount = os_patching['security_package_update_count']
  securityflag = '--security'
else
  updatecount = os_patching['package_update_count']
  securityflag = nil
end

run_pre_patching_command(os_patching['pre_patching_command'], log, starttime) if os_patching['pre_patching_command']

# There are no updates available, exit cleanly rebooting if the override flag is set
if updatecount.zero?
  if reboot == 'always'
    output('Success', reboot, security_only, 'No patches to apply, reboot triggered', '', '', '', pinned_pkgs, starttime, log)
    $stdout.flush
    do_reboot(log, 'No patches to apply, rebooting as requested', shutdown_cmd)
  else
    output('Success', reboot, security_only, 'No patches to apply', '', '', '', pinned_pkgs, starttime, log)
    log.info 'No patches to apply, exiting'
  end

  exit 0
end

# Run the patching
case os['family']
when 'RedHat'
  patch_rhel(yum_params, securityflag, timeout, log, starttime, reboot, security_only, pinned_pkgs)
when 'Debian'
  patch_debian(dpkg_params, securityflag, timeout, log, starttime, reboot, security_only, pinned_pkgs)
when 'windows'
  patch_windows(timeout, log, starttime, reboot, security_only)
when 'Suse'
  patch_suse(zypper_params, timeout, log, starttime, reboot, security_only, pinned_pkgs)
else
  log.error "Unsupported OS #{os['family']} - exiting"
  err(200, 'os_patching/unsupported_os', 'Unsupported OS', starttime)
end

log.info 'Patching complete'
log.info "Patching took #{Time.parse(Time.now.iso8601) - Time.parse(starttime)} seconds"

# Refresh the facts now that we've patched - for non-windows systems
# Windows scans can take an eternity after a patch run prior to being reboot (30+ minutes in a lab on 2008 versions..)
# Best not to delay the whole patching process here.
# Note that the fact refresh (which includes a scan) runs on system startup anyway - see os_patching puppet class
refresh_facts(log, fact_generation_cmd, starttime) unless os['family'] == 'windows'

# Reboot if the task has been told to and there is a requirement OR if reboot_override is set to true
needs_reboot = reboot_required(os['family'], os['release']['major'], reboot)
log.info "reboot_required returning #{needs_reboot}"

do_reboot(log, 'Reboot required, rebooting now', shutdown_cmd) if needs_reboot

log.info 'os_patching run complete'

exit 0
