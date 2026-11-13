{
  inputs,
  config,
  lib,
  ...
}:
let
  identity = {
    username = "uontabc";
    fullName = "uontabc";
    email = "uontabc@gmail.com";
  };
  mkHost = import ../../lib/mk-host.nix { inherit inputs identity; };
  enabledHosts = lib.filterAttrs (_: host: host.enable) config.hosts;
in
{
  options.hosts = lib.mkOption {
    description = "Host declarations, colocated with their machine-specific modules.";
    default = { };
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Expose this host as a NixOS configuration.";
          };
          system = lib.mkOption { type = lib.types.str; };
          configRoot = lib.mkOption {
            type = lib.types.str;
            default = "/home/${identity.username}/nixos-config";
          };
          module = lib.mkOption { type = lib.types.deferredModule; };
        };
      }
    );
  };

  config.flake = {
    lib.mkHost = mkHost;
    nixosConfigurations = lib.mapAttrs (
      name: host:
      mkHost name {
        inherit (host) system configRoot;
        modules = [
          host.module
        ]
        ++ lib.optional (config.flake.modules.nixos ? ${name}) config.flake.modules.nixos.${name};
      }
    ) enabledHosts;
  };
}
