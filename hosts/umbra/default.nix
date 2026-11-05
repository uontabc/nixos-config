{ inputs, self, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./machine.nix
    ./disko.nix
    ./proxy.nix
    self.modules.nixos.proxy-node
  ];

}
