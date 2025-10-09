# lint:ignore:autoloader_layout

# @summary An example profile class that sets up
#
# @param patch_window
#   The patch window to use.  This should be one of the windows defined in the
#   os_patching::patch_windows hash.  If not set, the default from the
#   os_patching class will be used.
#
# @param blackout_windows
#   A hash of blackout windows to use.  This will be merged with any blackout
#   windows defined in hiera under profiles::soe::patching::blackout_windows
#
# @param reboot_override
#   Override the default reboot behaviour.  This should be one of:
#     - 'always' - Always reboot after patching
#     - 'never'  - Never reboot after patching
#     - 'smart'  - Reboot only if required
#   If not set, the default from the os_patching class will be used.
#
class sample_patching_profile (
  Optional[String] $patch_window    = undef,
  Optional[Hash] $blackout_windows  = undef,
  Optional[String] $reboot_override = undef,
) {
# lint:endignore
  # Pull any blackout windows out of hiera
  $hiera_blackout_windows = lookup('profiles::soe::patching::blackout_windows',Hash,hash, {})

  # Merge the blackout windows from the parameter and hiera
  $full_blackout_windows = $hiera_blackout_windows + $blackout_windows

  # Call the os_patching class to set everything up
  class { 'os_patching':
    patch_window     => $patch_window,
    reboot_override  => $reboot_override,
    blackout_windows => $full_blackout_windows,
  }
}
