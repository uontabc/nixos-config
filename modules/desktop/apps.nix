{
  flake.modules.nixos.apps =
    { inputs, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
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
        inputs.helium-browser.packages.${system}.default
        inputs.rayburst-packages.packages.${system}.rayburst
        pkgs.kitty
        pkgs.pcmanfm
      ];

      # PCManFM provides file management only, not a second desktop/wallpaper layer.
      services.gvfs.enable = true;
      services.udisks2.enable = true;
      xdg.mime.defaultApplications = {
        "inode/directory" = "pcmanfm.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "text/html" = "helium.desktop";
        "application/xhtml+xml" = "helium.desktop";
      };
    };
}
