# @summary Patch nodes in a batch, is called from patch_group plan or patch_pql plan
#
# @param batch The batch of nodes to patch
# @param catch_errors Whether to catch errors during task execution
# @param noop_state Whether to consider noop state during health check
# @param run_health_check Whether to run a health check before patching
# @param service_enabled Whether the puppet service should be enabled during health check
# @param service_running Whether the puppet service should be running during health check
# @param runinterval The runinterval to use during health check
# @param debug Whether to enable debug output
#
# @return A hash containing the results of the patching operation
#
plan os_patching::patch_batch (
  TargetSpec $batch,
  Boolean $catch_errors     = true,
  Boolean $noop_state       = false,
  Boolean $run_health_check = false,
  Boolean $service_enabled  = true,
  Boolean $service_running  = true,
  Integer[0] $runinterval   = 1800,
  Boolean $debug            = false,
) {
  out::message("patch_batch.pp: Patching batch of nodes: ${batch}")
  out::message("patch_batch.pp: Health check is ${run_health_check}.")

  if $run_health_check {
    out::message('patch_batch.pp: Running health check before patching')
    # this comes from https://github.com/voxpupuli/puppet_health_check
    $health_checks = run_task('puppet_health_check::agent_health', $batch,
      _catch_errors          => $catch_errors,
      target_noop_state      => $noop_state,
      target_runinterval     => $runinterval,
      target_service_enabled => $service_enabled,
      target_service_running => $service_running,
    )

    if $debug {
      out::message('patch_batch.pp: Health check results:')
      out::message($health_checks)
    }

    # get nodes that are 'clean' from health check results
    $nodes_to_patch = ($health_checks.filter_set |$item| { $item.value['state'] == 'clean' }).map |$n| { $n.target }
    $skipped_nodes  = ($health_checks.filter_set |$item| { $item.status == 'failure' }).map |$n| { $n.target }

    if $debug {
      out::message('patch_batch.pp: Nodes to patch after health check:')
      out::message($nodes_to_patch)
      out::message('patch_batch.pp: Skipped nodes after health check:')
      out::message($skipped_nodes)
    }

    $patching_result = run_task('os_patching::patch_server', $nodes_to_patch,
      _catch_errors => $catch_errors,
    )

    if $debug {
      out::message('patch_batch.pp: Patching results:')
      out::message($patching_result)
    }
  } else {
    $patching_result = run_task('os_patching::patch_server', $batch,
      _catch_errors => $catch_errors,
    )

    if $debug {
      out::message('patch_batch.pp: Patching results:')
      out::message($patching_result)
    }

    $skipped_nodes            = [] # No skipped nodes if health check is not run
  }

  return(
    {
      targets      => $batch,
      patched      => $patching_result.ok_set.names,
      failed       => $patching_result.error_set.names,
      skipped      => $skipped_nodes,
      health_check => $run_health_check,
    }
  )
}
