{ inputs, lib, ... }:
let
  identity = {
    username = "uontabc";
    fullName = "uontabc";
    email = "uontabc@gmail.com";
  };
  hosts = import ../hosts;
  mkHost = import ../lib/mk-host.nix { inherit inputs identity; };
in
{
  # Hosts have their own target systems; they are not perSystem outputs.
  flake = {
    lib.mkHost = mkHost;
    nixosConfigurations = lib.mapAttrs mkHost hosts;
  };
}
