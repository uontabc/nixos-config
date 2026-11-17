{
  flake.modules.nixos.apps =
    { inputs, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      rkdeveloptoolGui = pkgs.callPackage ../../overlays/rkdeveloptool-gui { };
    in
    {
      # Cache for the maintainer's standalone Rayburst flake (formerly Motrix Next).
      nix.settings = {
        extra-substituters = [ "https://ccicnce113424.cachix.org" ];
        extra-trusted-public-keys = [
          "ccicnce113424.cachix.org-1:OWV4fSkx7o7TinVCSD98zPG8udShCIjhyaAdOIRNetw="
        ];
      };

      programs.obs-studio.enable = true;
      environment.systemPackages = [
        inputs.zen-browser.packages.${system}.beta
        inputs.rayburst-packages.packages.${system}.rayburst
        pkgs.kitty
        pkgs.pcmanfm
        pkgs.telegram-desktop
        rkdeveloptoolGui
      ];
      services.udev.packages = [ rkdeveloptoolGui ];

      # PCManFM provides file management only, not a second desktop/wallpaper layer.
      services.gvfs.enable = true;
      services.udisks2.enable = true;
      xdg.mime.defaultApplications = {
        "inode/directory" = "pcmanfm.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
      };
    };
}
