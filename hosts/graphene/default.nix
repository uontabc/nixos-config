{ ... }:
{
  imports = [
    ../../modules/wsl
    ../../modules/profiles/development.nix
  ];

  system.stateVersion = "26.05";
}
