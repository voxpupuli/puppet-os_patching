# @summary Patch nodes collected by a fact group
#
# @param group The fact group name to patch
# @param patch_in_batches Whether to patch nodes in batches
# @param batch_size The size of each batch if patching in batches
# @param run_health_check Whether to run a health check after patching
# @param debug Whether to enable debug output
# @param pql_query The PQL query to retrieve nodes in the group
#
# @return A hash containing the results of the patching operation
#
plan os_patching::patch_group (
  String[1] $group,
  String[1] $pql_query      = "inventory[certname] { facts.os_patching.group = '${group}'}",
  Boolean $patch_in_batches = true,
  Integer[0] $batch_size    = 15,
  Boolean $run_health_check = true,
  Boolean $debug            = false,
) {
  $pql_data = puppetdb_query($pql_query)
  $certnames = $pql_data.map |$item| { $item['certname'] }
  $targets   = get_targets($certnames)

  out::message("patch_group.pp: Patching group: ${group}")
  out::message("patch_group.pp: Targets in group: ${targets}")
  out::message("patch_group.pp: Patching in batches is ${patch_in_batches}")

  if $patch_in_batches {
    $batches = slice($targets, $batch_size)

    out::message("patch_group.pp: Patching in batches of size: ${batch_size}")
    out::message("patch_group.pp: Patching batches created: ${batches}")

    $batch_results = $batches.map |$batch| {
      # out::message("patch_group.pp: Patching with nodes: ${batch}")
      run_plan('os_patching::patch_batch',
        {
          batch            => $batch,
          run_health_check => $run_health_check,
          debug            => $debug,
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
    out::message("patch_group.pp: Patching all targets at once: ${targets}")
    $result = run_plan('os_patching::patch_batch',
      {
        batch            => $targets,
        run_health_check => $run_health_check,
        debug            => $debug,
      }
    )
  }

  return $result
}
