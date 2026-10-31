{ ... }:
{
  imports = [
    ./modules/system.nix
    ./modules/network.nix
    ./modules/development.nix
    ./modules/gpu.nix
    ./home
  ];

  # Installation compatibility baseline. This is not an upgrade selector.
  system.stateVersion = "26.05";
}
