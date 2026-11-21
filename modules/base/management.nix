{ ... }:
{
  flake.modules.nixos.management =
    {
      lib,
      pkgs,
      configRoot,
      hostKey,
      ...
    }:
    {
      programs.nh = {
        enable = true;
        flake = configRoot;
      };
      environment.systemPackages = [
        pkgs.git
        pkgs.gh
      ];
      environment.shellAliases.rebuild = "${lib.getExe pkgs.nixos-rebuild} switch --sudo --flake ${lib.escapeShellArg "${configRoot}#${hostKey}"}";
    };
}
