{ ... }:
{
  flake.modules.nixos.pi-extensions =
    { config, pkgs, ... }:
    let
      examples = "${config.programs.pi.coding-agent.package}/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions";
    in
    {
      programs.pi.coding-agent.extensions = [
        "${examples}/plan-mode"
        "${examples}/questionnaire.ts"
        "${examples}/interactive-shell.ts"
      ];
    };
}
