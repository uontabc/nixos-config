{ ... }:
{
  flake.modules.nixos.docker =
    { identity, lib, ... }:
    {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        logDriver = "local";
        daemon.settings = {
          "registry-mirrors" = lib.mkDefault [ "https://docker.m.daocloud.io" ];
          "live-restore" = true;
          "log-opts" = {
            "max-size" = "10m";
            "max-file" = "3";
          };
        };
      };

      # The NixOS Docker module inherits networking.proxy for the daemon.
      # WSL supplies its Windows proxy; native hosts have their own network settings.
      users.users.${identity.username}.extraGroups = [ "docker" ];
    };
}
