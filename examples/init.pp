class { 'os_patching':
  patch_window     => 'Week3',
  reboot_override  => 'smart',
  fact_upload      => false,
  blackout_windows => {
    'End of year change freeze' => {
      'start' => '2018-12-15T00:00:00+10:00',
      'end'   => '2019-01-15T23:59:59+10:00',
    },
    'End of DST'                => {
      'start' => '2019-04-07T00:00:00+10:00',
      'end'   => '2019-04-08T23:59:59+10:00',
    },
  },
}
