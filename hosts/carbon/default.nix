{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./machine.nix
    ./disko.nix
    ./impermanence.nix
    ../../modules/profiles/development.nix
    ../../modules/profiles/laptop.nix
    ./graphics.nix
    ./desktop.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;
  # Fresh-install compatibility baseline; keep it after subsequent upgrades.
  system.stateVersion = "26.05";
}
