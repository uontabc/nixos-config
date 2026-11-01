{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./machine.nix
    ./disko.nix
    ./proxy.nix
    ../../modules/profiles/proxy-node.nix
  ];

}
