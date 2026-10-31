{ ... }:
{
  imports = [
    ./machine.nix
    ../../modules/profiles/development.nix
    ../../modules/profiles/laptop.nix
    ./graphics.nix
    ./desktop.nix
  ];

  networking.hostName = "laptop";
  hardware.cpu.amd.updateMicrocode = true;
  # First native installation uses the pinned NixOS 26.05 release.
  system.stateVersion = "26.05";
}
