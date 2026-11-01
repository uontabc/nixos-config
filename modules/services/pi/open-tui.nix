{ pkgs, ... }:
let
  openTui = pkgs.callPackage ../../../packages/pi-open-tui { };
in
{
  # The extension uses Pi's active theme; UI preferences remain writable in home.
  programs.pi.coding-agent.extensions = [ "${openTui}/extensions/open-tui/index.ts" ];
}
