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
    # Keep host drives and explicit .exe calls, without importing Windows tools.
    interop.includePath = false;
    startMenuLaunchers = false;
    wslConf.interop.appendWindowsPath = false;
    wslConf.automount.options = "metadata,uid=1000,gid=100,umask=022";
  };

  users.users.${identity.username}.uid = 1000;
}
