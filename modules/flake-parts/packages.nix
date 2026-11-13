{
  perSystem =
    { pkgs, ... }:
    {
      packages.rkdeveloptool-gui = pkgs.callPackage ../../overlays/rkdeveloptool-gui { };
    };
}
