{ self, pkgs, ... }:
{
  imports = [
    self.modules.nixos.wsl
    self.modules.nixos.development
    ../../home/yazi.nix
  ];

  # Keep Zellij opt-in: no managed config or automatic shell startup.
  environment.systemPackages = [ pkgs.zellij ];

  system.stateVersion = "26.05";
}
