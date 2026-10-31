{ ... }:
{
  # Import this server's existing configuration, including its hardware module,
  # boot settings, SSH access, and original system.stateVersion.
  # Example after copying the existing /etc/nixos tree into ./existing/:
  # imports = [ ./existing/configuration.nix ];

  assertions = [
    {
      assertion = false;
      message = "Server template: replace hosts/server/machine.nix with this server's existing configuration and original system.stateVersion before deployment.";
    }
  ];
}
