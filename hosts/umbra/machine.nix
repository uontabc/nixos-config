{ ... }:
{
  # Future fresh reinstall, not in-place conversion of the running VPS.
  # Import provider hardware/network settings, configure SSH keys/accounts,
  # and set the fresh installation's system.stateVersion before deployment.
  # imports = [ ./hardware-configuration.nix ];
  fleet.storage.vps = {
    disk = null; # verified whole /dev/disk/by-id/... (will be erased on reinstall)
    firmware = null; # "uefi" or "bios", verified in rescue mode
  };
  assertions = [
    {
      assertion = false;
      message = "VPS reinstall template: verify disk, firmware and architecture; supply provider networking, SSH access and system.stateVersion before removing this installation guard.";
    }
  ];
}
