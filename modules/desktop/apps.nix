{
  flake.modules.nixos.apps =
    {
      identity,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      rkdeveloptoolGui = pkgs.callPackage ../../overlays/rkdeveloptool-gui { };
      mimeDefaults = {
        "inode/directory" = "pcmanfm.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "x-scheme-handler/ton" = "org.telegram.desktop.desktop";
      };
    in
    {
      # Apply to every pkgs.qq entry point, including the existing user profile.
      # Steam is not Electron and still needs XWayland; these flags are QQ-only.
      nixpkgs.overlays = [
        (_final: prev: {
          # Wrap the cached package rather than repacking Tencent's binary.
          qq = prev.symlinkJoin {
            name = "${prev.qq.name}-wayland";
            paths = [ prev.qq ];
            nativeBuildInputs = [ prev.makeWrapper ];
            postBuild = ''
              wrapProgram "$out/bin/qq" \
                --add-flags "--ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3"
            '';
            inherit (prev.qq) meta;
          };
        })
      ];

      programs.obs-studio.enable = true;
      environment.systemPackages = [
        inputs.zen-browser.packages.${system}.beta
        pkgs.kitty
        pkgs.pcmanfm
        pkgs.telegram-desktop
        pkgs.qq
        rkdeveloptoolGui
      ];
      services.udev.packages = [ rkdeveloptoolGui ];

      # PCManFM provides file management only, not a second desktop/wallpaper layer.
      services.gvfs.enable = true;
      services.udisks2.enable = true;
      # User mimeapps.list wins over system defaults. Manage it at the winning
      # location and retain the Telegram associations already used by this user.
      users.users.${identity.username}.maid.file.xdg_config."mimeapps.list".text =
        lib.generators.toINI { }
          {
            "Default Applications" = mimeDefaults;
            "Added Associations" = lib.mapAttrs (_: desktop: "${desktop};") mimeDefaults;
          };
    };
}
