{ inputs, identity, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ./network.nix
    ./gpu.nix
  ];

  wsl = {
    enable = true;
    defaultUser = identity.username;
    useWindowsDriver = true;
    wslConf.automount.options = "metadata,uid=1000,gid=100,umask=022";
  };

  users.users.${identity.username}.uid = 1000;
}
