{ ... }:
{
  flake.modules.nixos.management =
    {
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
        (pkgs.writeShellApplication {
          name = "rebuild";
          runtimeInputs = [ pkgs.nixos-rebuild ];
          text = ''
            exec nixos-rebuild switch --sudo --flake ${configRoot}#${hostKey} "$@"
          '';
        })
      ];
    };
}
