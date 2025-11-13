# @summary Patch nodes collected by a PQL query
#
# @param batch_size The size of each batch if patching in batches
# @param catch_errors Whether to catch errors during task execution
# @param clean_cache Whether to clean the package manager cache before patching
# @param debug Whether to enable debug output
# @param dpkg_params Additional parameters for apt/dpkg
# @param noop_state Whether to consider noop state during health check
# @param patch_in_batches Whether to patch nodes in batches
# @param pql_query The PQL query to retrieve nodes to patch
# @param reboot Reboot strategy after patching
# @param run_health_check Whether to run a health check after patching
# @param runinterval The runinterval to use during health check
# @param security_only Whether to apply only security updates
# @param service_enabled Whether the puppet service should be enabled during health check
# @param service_running Whether the puppet service should be running during health check
# @param timeout The timeout for the patching task
# @param yum_params Additional parameters for yum
# @param zypper_params Additional parameters for zypper
#
# @return A hash containing the results of the patching operation
#
plan os_patching::patch_pql (
  Boolean $catch_errors     = true,
  Boolean $debug            = false,
  Boolean $noop_state       = false,
  Boolean $patch_in_batches = true,
  Boolean $run_health_check = true,
  Boolean $service_enabled  = true,
  Boolean $service_running  = true,
  Integer[1] $batch_size    = 15,
  Integer[0] $runinterval   = 1800,
  Optional[Boolean] $clean_cache   = undef,
  Optional[Boolean] $security_only = undef,
  Optional[Integer[1]] $timeout    = undef,
  Optional[String] $dpkg_params   = undef,
  Optional[String] $yum_params    = undef,
  Optional[String] $zypper_params = undef,
  Optional[Variant[Boolean, Enum['always', 'never', 'patched', 'smart']]] $reboot = undef,
  String[1] $pql_query      = 'inventory[certname] { facts.os.family = "redhat" }',
) {
  $pql_data = puppetdb_query($pql_query)
  $certnames = $pql_data.map |$item| { $item['certname'] }
  $targets   = get_targets($certnames)

  out::message("patch_pql.pp: Patching PQL query: ${pql_query}")
  out::message("patch_pql.pp: Targets in group: ${targets}")
  out::message("patch_pql.pp: Patching in batches is ${patch_in_batches}")

  if $patch_in_batches {
    $batches = slice($targets, $batch_size)

    out::message("patch_pql.pp: Patching in batches of size: ${batch_size}")
    out::message("patch_pql.pp: Patching batches created: ${batches}")

    $batch_results = $batches.map |$batch| {
      # out::message("patch_pql.pp: Patching with nodes: ${batch}")
      run_plan('os_patching::patch_batch',
        {
          batch            => $batch,
          catch_errors     => $catch_errors,
          clean_cache      => $clean_cache,
          debug            => $debug,
          dpkg_params      => $dpkg_params,
          noop_state       => $noop_state,
          reboot           => $reboot,
          run_health_check => $run_health_check,
          runinterval      => $runinterval,
          security_only    => $security_only,
          service_enabled  => $service_enabled,
          service_running  => $service_running,
          timeout          => $timeout,
          yum_params       => $yum_params,
          zypper_params    => $zypper_params,
        }
      )
    }

    # Merge all batch results into a single hash by combining arrays
    $result = {
      'targets'      => $batch_results.map |$r| { $r['targets'] }.flatten,
      'patched'      => $batch_results.map |$r| { $r['patched'] }.flatten,
      'failed'       => $batch_results.map |$r| { $r['failed'] }.flatten,
      'skipped'      => $batch_results.map |$r| { $r['skipped'] }.flatten,
      'health_check' => $batch_results[0]['health_check'],
    }
  } else {
    out::message('patch_pql.pp: Patching in batches is disabled')
    out::message("patch_pql.pp: Patching all targets at once: ${targets}")
    $result = run_plan('os_patching::patch_batch',
      {
        batch            => $targets,
        catch_errors     => $catch_errors,
        clean_cache      => $clean_cache,
        debug            => $debug,
        dpkg_params      => $dpkg_params,
        noop_state       => $noop_state,
        reboot           => $reboot,
        run_health_check => $run_health_check,
        runinterval      => $runinterval,
        security_only    => $security_only,
        service_enabled  => $service_enabled,
        service_running  => $service_running,
        timeout          => $timeout,
        yum_params       => $yum_params,
        zypper_params    => $zypper_params,
      }
    )
  }

  return $result
}
