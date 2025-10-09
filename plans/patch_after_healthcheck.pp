# @summary An example plan that uses the
#   [puppet health check](https://forge.puppet.com/albatrossflavour/puppet_health_check)
#   module to perform a pre-check on the nodes you're planning to patch.  If the nodes pass the
#   check, they get patched
plan os_patching::patch_after_healthcheck (
  TargetSpec $nodes,
  Optional[Boolean] $noop_state = false,
  Optional[Integer] $runinterval = 1800,
) {
  # Run an initial health check to make sure the target nodes are ready

  $health_checks = run_task('puppet_health_check::agent_health',
    $nodes,
    target_noop_state      => $noop_state,
    target_service_enabled => true,
    target_service_running => true,
    target_runinterval     => $runinterval,
    '_catch_errors'        => true,
  )

  $nodes_to_patch = $health_checks.filter | $items | { $items.value['state'] == 'clean' }
  $nodes_skipped  = $health_checks.filter | $items | { $items.value['state'] != 'clean' }

  $skipped_targets = $nodes_skipped.map | $value | { $value['certname'] }
  $targets = $nodes_to_patch.map | $value | { $value['certname'] }

  out::message("Skipping the following nodes due to health check failures : ${nodes_skipped}")
  return run_task('os_patching::patch_server', $targets)
}
