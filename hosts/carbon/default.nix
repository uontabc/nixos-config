{ inputs, self, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./machine.nix
    ./disko.nix
    ./impermanence.nix
    self.modules.nixos.development
    self.modules.nixos.laptop
    ./graphics.nix
    ./desktop.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;
  # Fresh-install compatibility baseline; keep it after subsequent upgrades.
  system.stateVersion = "26.05";
}
