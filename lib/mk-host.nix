{ inputs, identity }:
hostKey:
{
  system,
  modules,
  configRoot ? "/home/${identity.username}/nixos-config",
}:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit (inputs) self;
    inherit
      inputs
      identity
      hostKey
      configRoot
      ;
  };
  modules = [
    inputs.hjem.nixosModules.default
    inputs.self.modules.nixos.common
  ]
  ++ modules;
}
