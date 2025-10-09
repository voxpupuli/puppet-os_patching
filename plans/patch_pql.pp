# @summary Patch nodes collected by a PQL query
#
plan os_patching::patch_pql (
  String[1] $pql_query      = 'inventory[certname] { facts.os.family = "redhat" }',
  Boolean $patch_in_batches = true,
  Integer $batch_size       = 15,
) {
  $pql_query = puppetdb_query($pql_query)
  $certnames = $pql_query.map |$item| { $item['certname'] }
  $targets   = get_targets($certnames)

  if $patch_in_batches {
    $batches = slice($targets, $batch_size)

    $batches.each |$batch| {
      $result = run_plan('os_patching::patch_batch', { batch => $batch })
    }
  } else {
    $result = run_plan('os_patching::patch_batch', { batch => $targets })
  }
}
