{ ... }:
{
  # Compatibility entry point. Flakes register hosts through hosts/default.nix.
  imports = [ ./hosts/wsl ];
}
