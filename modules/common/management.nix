{
  pkgs,
  configRoot,
  hostKey,
  ...
}:
{
  environment.sessionVariables.NH_FLAKE = configRoot;
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
}
