# @summary Patch nodes in a batch
#
plan os_patching::patch_batch (
  Array $batch              = [],
  Boolean $catch_errors     = true,
  Boolean $noop_state       = false,
  Boolean $run_health_check = false,
  Boolean $service_enabled  = true,
  Boolean $service_running  = true,
  Integer $runinterval      = 1800,
) {
  out::message("patch_batch.pp: Patching batch of nodes: ${batch}")

  $targets   = get_targets($batch)

  if $run_health_check {
    out::message('patch_batch.pp: Running health check before patching')
    run_task('os_patching::health_check', $targets,
      _catch_errors          => $catch_errors,
      target_noop_state      => $noop_state,
      target_runinterval     => $runinterval,
      target_service_enabled => $service_enabled,
      target_service_running => $service_running,
    )

    $nodes_to_patch = $health_checks.filter | $items | { $items.value['state'] == 'clean' }
    $nodes_skipped  = $health_checks.filter | $items | { $items.value['state'] != 'clean' }

    $skipped_nodes = $nodes_skipped.map | $value | { $value['certname'] }
    $patchable_nodes = $nodes_to_patch.map | $value | { $value['certname'] }

    $task_result = run_task('os_patching::patch_server', $patchable_nodes,
      _catch_errors => $catch_errors,
    )

    $successful_patched_nodes = $task_result.ok_set.names
    $failed_patched_nodes     = $task_result.error_set.names
  } else {
    out::message('patch_batch.pp: Health check is disabled.')
    $task_result = run_task('os_patching::patch_server', $targets,
      _catch_errors => $catch_errors,
    )

    log::debug("patch_batch.pp: Patching task result for ${targets}: ${task_result}")

    $successful_patched_nodes = $task_result.ok_set.names
    $failed_patched_nodes     = $task_result.error_set.names
    $skipped_nodes            = [] # No skipped nodes if health check is not run
  }

  return(
    {
      targets      => $targets,
      patched      => $successful_patched_nodes,
      failed       => $failed_patched_nodes,
      skipped      => $skipped_nodes,
      health_check => $run_health_check,
    }
  )
}
