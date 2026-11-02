{ ... }:
{
  flake.modules.nixos.pi-web-search =
    { pkgs, ... }:
    let
      webSearch = pkgs.callPackage ../../../packages/pi-web-search { };
    in
    {
      # Use the user's current provider/auth; keep optional web-search.json writable.
      programs.pi.coding-agent.extensions = [ "${webSearch}/src/index.ts" ];
    };
}
