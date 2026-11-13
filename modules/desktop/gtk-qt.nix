{
  flake.modules.nixos.gtk-qt =
    {
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      gtk = pkgs.tokyonight-gtk-theme.override {
        colorVariants = [ "dark" ];
        sizeVariants = [ "standard" ];
        themeVariants = [ "default" ];
        iconVariants = [ "Dark" ];
      };
      # The GTK package does not ship a Qt theme. Pin the matching Kvantum assets.
      kvantum = pkgs.fetchFromGitHub {
        owner = "0xsch1zo";
        repo = "Kvantum-Tokyo-Night";
        rev = "b1e6b0925ba15784ea4b344d734564e9357cbd86";
        hash = "sha256-fmYGEeK1RND8RpVM5QFgruql3lCs50LBXVApXqgwzzk=";
      };
      cursorSettings = ''
        [Icon Theme]
        Inherits=${theme.cursorName}
      '';
      gtkSettings = ''
        [Settings]
        gtk-theme-name=${theme.gtkName}
        gtk-icon-theme-name=${theme.icons}
        gtk-font-name=${theme.fonts.sans} ${toString theme.fonts.size}
        gtk-cursor-theme-name=${theme.cursorName}
        gtk-cursor-theme-size=${toString theme.cursorSize}
        gtk-application-prefer-dark-theme=true
      '';
      qtSettings = ''
        [Appearance]
        style=kvantum
        icon_theme=${theme.icons}
        [Fonts]
        general="${theme.fonts.sans},${toString theme.fonts.size},-1,5,50,0,0,0,0,0"
        fixed="${theme.fonts.mono},${toString theme.fonts.size},-1,5,50,0,0,0,0,0"
      '';
    in
    {
      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            # Only these theme/font keys are locked; other preferences stay writable.
            lockAll = true;
            settings."org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = theme.gtkName;
              icon-theme = theme.icons;
              cursor-theme = theme.cursorName;
              cursor-size = lib.gvariant.mkInt32 theme.cursorSize;
              font-name = "${theme.fonts.sans} ${toString theme.fonts.size}";
              document-font-name = "${theme.fonts.sans} ${toString theme.fonts.size}";
              monospace-font-name = "${theme.fonts.mono} ${toString theme.fonts.size}";
            };
          }
        ];
      };
      qt = {
        enable = true;
        platformTheme = "qt5ct";
        style = "kvantum";
      };
      environment.systemPackages = [
        gtk
        pkgs.tela-icon-theme
        pkgs.bibata-cursors
        pkgs.xdg-terminal-exec
      ];
      environment.sessionVariables = {
        TERMINAL = "kitty";
        XCURSOR_THEME = theme.cursorName;
        XCURSOR_SIZE = toString theme.cursorSize;
      };
      hjem.users.${identity.username} = {
        # Legacy Xcursor users and clients that request the "default" theme.
        files.".icons/default/index.theme".text = cursorSettings;
        # GTK 2 does not read gtk-3.0/settings.ini (some game launchers still use it).
        files.".gtkrc-2.0".text = ''
          gtk-theme-name="${theme.gtkName}"
          gtk-icon-theme-name="${theme.icons}"
          gtk-font-name="${theme.fonts.sans} ${toString theme.fonts.size}"
          gtk-cursor-theme-name="${theme.cursorName}"
          gtk-cursor-theme-size=${toString theme.cursorSize}
        '';
        xdg.data.files."icons/default/index.theme".text = cursorSettings;
        xdg.config.files = {
          "gtk-3.0/settings.ini".text = gtkSettings;
          "gtk-4.0/settings.ini".text = gtkSettings;
          "gtk-4.0/gtk.css".text = ''@import url("${gtk}/share/themes/${theme.gtkName}/gtk-4.0/gtk.css");'';
          "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${theme.kvantumName}\n";
          "Kvantum/${theme.kvantumName}".source = "${kvantum}/${theme.kvantumName}";
          "qt5ct/qt5ct.conf".text = qtSettings;
          "qt6ct/qt6ct.conf".text = qtSettings;
          "xdg-terminals.list".text = "kitty.desktop\n";
        };
      };
    };
}
