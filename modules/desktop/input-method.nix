{
  flake.modules.nixos.input-method =
    {
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      fcitxTheme = pkgs.callPackage ../../overlays/fcitx5-deepinlike-theme { };
      configFile = import ../../lib/maid-config-file.nix { inherit pkgs; };
    in
    {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          addons = [
            fcitxTheme
            (pkgs.fcitx5-rime.override {
              rimeDataPkgs = with pkgs; [
                rime-data
                rime-wanxiang
              ];
            })
          ];
        };
      };

      environment.sessionVariables = {
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "ibus";
      };
      # GTK candidate panels find themes through XDG_DATA_DIRS, not the private
      # fcitx5-with-addons path. NixOS does not link share/fcitx5 by default.
      environment.systemPackages = [ fcitxTheme ];
      environment.pathsToLink = [ "/share/fcitx5" ];

      # NixOS supplies the daemon/addons only. User settings belong to nix-maid,
      # not a second /etc/xdg configuration shadowed by Fcitx's saved profile.
      users.users.${identity.username}.maid = lib.mkMerge [
        {
          file.xdg_data."fcitx5/rime/default.custom.yaml".text = ''
            patch:
              __include: wanxiang_suggested_default:/
          '';
          # Fcitx's Keyboard engine otherwise consumes Ctrl+Alt+H/J before
          # Wayland clients (including Kitty) receive the key press.
          file.xdg_config."fcitx5/conf/keyboard.conf".text = lib.generators.toINI { } {
            "Hint Trigger"."0" = "Control+Alt+Shift+H";
            "One Time Hint Trigger"."0" = "Control+Alt+Shift+J";
          };
          file.xdg_config."fcitx5/conf/classicui.conf".text = lib.generators.toINIWithGlobalSection { } {
            globalSection = {
              Theme = theme.fcitxName;
              DarkTheme = "deepinExp-dark";
              UseDarkTheme = "False";
              UseAccentColor = "False";
              Font = "${theme.fonts.sans} ${toString theme.fonts.size}";
            };
            sections = { };
          };
        }
        (configFile {
          path = "fcitx5/profile";
          # Fcitx saves the active input method. Track defaults without making
          # the running daemon write into the Nix store or freezing its state.
          writable = true;
          text = lib.generators.toINI { } {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "rime";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "rime";
            GroupOrder."0" = "Default";
          };
        })
      ];
    };
}
