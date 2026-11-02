{ self, ... }:
{
  imports = [
    self.modules.nixos.wsl
    self.modules.nixos.development
    ../../home/yazi.nix
  ];

  system.stateVersion = "26.05";
}
