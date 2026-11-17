{
  perSystem =
    { pkgs, ... }:
    {
      packages.rkdeveloptool-gui = pkgs.callPackage ../../overlays/rkdeveloptool-gui { };
      packages.fcitx5-deepinlike-theme = pkgs.callPackage ../../overlays/fcitx5-deepinlike-theme { };
    };
}
