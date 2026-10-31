{ ... }:
{
  # Replace this module with imports of the VPS's existing configuration.
  # Preserve boot, disks, networking, SSH accounts/keys, and stateVersion.
  # Example, after copying the existing /etc/nixos tree into ./existing/:
  # imports = [ ./existing/configuration.nix ];

  assertions = [
    {
      assertion = false;
      message = "VPS template: replace hosts/vps/machine.nix with this VPS's existing configuration and original system.stateVersion before deployment.";
    }
  ];
}
