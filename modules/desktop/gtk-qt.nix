{
  flake.modules.nixos.gtk-qt =
    {
      config,
      identity,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      c = theme.colors;
      # GTK 2 has no CSS support; supply the same palette through its rc format.
      gtk = pkgs.writeTextDir "share/themes/${theme.gtkName}/gtk-2.0/gtkrc" ''
        gtk-color-scheme = "fg_color:${c.text}\nbg_color:${c.base}\ntext_color:${c.text}\nbase_color:${c.base}\nselected_fg_color:${c.base}\nselected_bg_color:${c.blue}\ninsensitive_fg_color:${c.subtext0}\ninsensitive_bg_color:${c.surface0}"
        style "bluney" {
          fg[NORMAL] = "${c.text}"
          fg[ACTIVE] = "${c.text}"
          fg[PRELIGHT] = "${c.text}"
          fg[SELECTED] = "${c.base}"
          fg[INSENSITIVE] = "${c.subtext0}"
          bg[NORMAL] = "${c.base}"
          bg[ACTIVE] = "${c.surface0}"
          bg[PRELIGHT] = "${c.surface0}"
          bg[SELECTED] = "${c.blue}"
          bg[INSENSITIVE] = "${c.surface0}"
          text[NORMAL] = "${c.text}"
          text[ACTIVE] = "${c.text}"
          text[PRELIGHT] = "${c.text}"
          text[SELECTED] = "${c.base}"
          text[INSENSITIVE] = "${c.subtext0}"
          base[NORMAL] = "${c.base}"
          base[ACTIVE] = "${c.surface0}"
          base[PRELIGHT] = "${c.surface0}"
          base[SELECTED] = "${c.blue}"
          base[INSENSITIVE] = "${c.surface0}"
        }
        class "*" style "bluney"
      '';
      configHome = "${config.users.users.${identity.username}.home}/.config";
      cursorSettings = ''
        [Icon Theme]
        Inherits=${theme.cursorName}
      '';
      gtkSettings = ''
        [Settings]
        gtk-theme-name=adw-gtk3
        gtk-icon-theme-name=${theme.icons}
        gtk-font-name=${theme.fonts.sans} ${toString theme.fonts.size}
        gtk-cursor-theme-name=${theme.cursorName}
        gtk-cursor-theme-size=${toString theme.cursorSize}
        gtk-application-prefer-dark-theme=false
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
      # NixOS provides D-Bus support; nix-maid owns the per-user settings below.
      # Do not lock the same keys in a system dconf database as well.
      programs.dconf.enable = true;
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
      users.users.${identity.username}.maid = {
        gsettings.settings.org.gnome.desktop.interface = {
          color-scheme = "prefer-light";
          icon-theme = theme.icons;
          cursor-theme = theme.cursorName;
          cursor-size = theme.cursorSize;
          font-name = "${theme.fonts.sans} ${toString theme.fonts.size}";
          document-font-name = "${theme.fonts.sans} ${toString theme.fonts.size}";
          monospace-font-name = "${theme.fonts.mono} ${toString theme.fonts.size}";
        };
        # Legacy Xcursor users and clients that request the "default" theme.
        file.home.".icons/default/index.theme".text = cursorSettings;
        # GTK 2 does not read gtk-3.0/settings.ini (some game launchers still use it).
        file.home.".gtkrc-2.0".text = ''
          gtk-theme-name="${theme.gtkName}"
          gtk-icon-theme-name="${theme.icons}"
          gtk-font-name="${theme.fonts.sans} ${toString theme.fonts.size}"
          gtk-cursor-theme-name="${theme.cursorName}"
          gtk-cursor-theme-size=${toString theme.cursorSize}
        '';
        file.xdg_data."icons/default/index.theme".text = cursorSettings;
        file.xdg_config = {
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
