# @summary Patch nodes collected by a fact group
#
plan os_patching::patch_group (
  String[1] $group,
  Boolean $patch_in_batches = true,
  Integer $batch_size       = 15,
) {
  $pql_query = puppetdb_query("inventory[certname] { facts.os_patching.group = '${group}'}")
  $certnames = $pql_query.map |$item| { $item['certname'] }
  $targets   = get_targets($certnames)

  out::message("patch_group.pp: Patching group: ${group}")
  out::message("patch_group.pp: Targets in group: ${targets}")

  if $patch_in_batches {
    out::message('patch_group.pp: Patching in batches is enabled')
    out::message("patch_group.pp: Patching in batches of size: ${batch_size}")

    $batches = slice($targets, $batch_size)
    out::message("patch_group.pp: Patching batches created: ${batches}")

    $batch_results = $batches.map |$batch| {
      # out::message("patch_group.pp: Patching with nodes: ${batch}")
      run_plan('os_patching::patch_batch', { batch => $batch })
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
    out::message('patch_group.pp: Patching in batches is disabled')
    out::message("patch_group.pp: Patching all targets at once: ${targets}")
    $result = run_plan('os_patching::patch_batch', { batch => $targets })
  }

  return $result
}
