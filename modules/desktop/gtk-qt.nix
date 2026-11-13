{
  flake.modules.nixos.gtk-qt =
    {
      config,
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
      configHome = config.hjem.users.${identity.username}.xdg.config.directory;
      cursorSettings = ''
        [Icon Theme]
        Inherits=${theme.cursorName}
      '';
      gtkSettings = ''
        [Settings]
        gtk-theme-name=adw-gtk3-dark
        gtk-icon-theme-name=${theme.icons}
        gtk-font-name=${theme.fonts.sans} ${toString theme.fonts.size}
        gtk-cursor-theme-name=${theme.cursorName}
        gtk-cursor-theme-size=${toString theme.cursorSize}
        gtk-application-prefer-dark-theme=true
      '';
      qtSettings = qtVersion: ''
        [Appearance]
        style=Fusion
        custom_palette=true
        color_scheme_path=${configHome}/qt${qtVersion}ct/colors/noctalia.conf
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
            # Keep fonts/icons/cursor fixed; Noctalia may select the GTK theme.
            lockAll = true;
            settings."org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
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
      };
      environment.systemPackages = [
        gtk # GTK 2 fallback; GTK 3/4 colors come from Noctalia.
        pkgs.adw-gtk3
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
          # Import generated colors without letting hooks replace Nix-managed files.
          "gtk-3.0/gtk.css".text = ''@import url("noctalia.css");'';
          "gtk-4.0/gtk.css".text = ''@import url("noctalia.css");'';
          "qt5ct/qt5ct.conf".text = qtSettings "5";
          "qt6ct/qt6ct.conf".text = qtSettings "6";
          "xdg-terminals.list".text = "kitty.desktop\n";
        };
      };
    };
}
