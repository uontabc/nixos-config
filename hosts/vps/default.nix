{ ... }:
{
  imports = [
    ./machine.nix
    ./proxy.nix
    ../../modules/profiles/proxy-node.nix
  ];

  networking.hostName = "vps";
}
