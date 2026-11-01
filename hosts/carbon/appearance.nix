{ identity, pkgs, ... }:
let
  theme = import ../../lib/theme.nix;
  gtk = pkgs.catppuccin-gtk.override {
    variant = theme.flavour;
    accents = [ theme.accent ];
    size = "standard";
    tweaks = [ "normal" ];
  };
  kvantum = pkgs.catppuccin-kvantum.override {
    variant = theme.flavour;
    accent = theme.accent;
  };
  gtkSettings = ''
    [Settings]
    gtk-theme-name=${theme.gtkName}
    gtk-icon-theme-name=${theme.icons}
    gtk-font-name=${theme.fonts.sans} ${toString theme.fonts.size}
    gtk-cursor-theme-name=${theme.cursorName}
    gtk-cursor-theme-size=24
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
  programs.dconf.enable = true;
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };
  environment.systemPackages = [
    gtk
    kvantum
    pkgs.papirus-icon-theme
    pkgs.catppuccin-cursors.mochaMauve
    pkgs.xdg-terminal-exec
  ];
  environment.sessionVariables = {
    TERMINAL = "ghostty";
    XCURSOR_THEME = theme.cursorName;
    XCURSOR_SIZE = "24";
  };
  fonts.fontconfig.defaultFonts = {
    monospace = [ theme.fonts.mono ];
    sansSerif = [
      theme.fonts.sans
      "Noto Sans CJK SC"
    ];
    serif = [
      "Noto Serif"
      "Noto Serif CJK SC"
    ];
  };
  hjem.users.${identity.username}.xdg.config.files = {
    "gtk-3.0/settings.ini".text = gtkSettings;
    "gtk-4.0/settings.ini".text = gtkSettings;
    "gtk-4.0/gtk.css".text = ''@import url("${gtk}/share/themes/${theme.gtkName}/gtk-4.0/gtk.css");'';
    "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${theme.kvantumName}\n";
    "Kvantum/${theme.kvantumName}".source = "${kvantum}/share/Kvantum/${theme.kvantumName}";
    "qt5ct/qt5ct.conf".text = qtSettings;
    "qt6ct/qt6ct.conf".text = qtSettings;
    "xdg-terminals.list".text = "com.mitchellh.ghostty.desktop\n";
  };
}
