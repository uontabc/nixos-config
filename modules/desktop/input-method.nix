{
  flake.modules.nixos.input-method =
    {
      config,
      identity,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      fcitxTheme = pkgs.callPackage ../../overlays/fcitx5-deepinlike-theme { };
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
          settings = {
            inputMethod = {
              "Groups/0" = {
                Name = "Default";
                "Default Layout" = "us";
                DefaultIM = "keyboard-us";
              };
              "Groups/0/Items/0".Name = "keyboard-us";
              "Groups/0/Items/1".Name = "rime";
              GroupOrder."0" = "Default";
            };
            addons.classicui.globalSection = {
              Theme = theme.fcitxName;
              DarkTheme = "deepinExp-dark";
              UseDarkTheme = false;
              UseAccentColor = false;
              Font = "${theme.fonts.sans} ${toString theme.fonts.size}";
            };
          };
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

      users.users.${identity.username}.maid = {
        file.xdg_data."fcitx5/rime/default.custom.yaml".text = ''
          patch:
            __include: wanxiang_suggested_default:/
        '';
        # A user config wins over /etc/xdg; replace old plasma theme overrides.
        # Rime's dictionaries and runtime data remain writable.
        file.xdg_config."fcitx5/conf/classicui.conf" = {
          text = config.environment.etc."xdg/fcitx5/conf/classicui.conf".text;
        };
      };
    };
}
