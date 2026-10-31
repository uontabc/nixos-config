{ ... }:
{
  imports = [
    ../../modules/wsl
    ../../modules/profiles/development.nix
  ];

  # Preserve the installed hostname; the flake selector is `wsl`.
  networking.hostName = "nixos";
  system.stateVersion = "26.05";
}
