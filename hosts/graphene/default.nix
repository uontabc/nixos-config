{ ... }:
{
  imports = [
    ../../modules/wsl
    ../../modules/profiles/development.nix
    ../../home/yazi.nix
  ];

  system.stateVersion = "26.05";
}
