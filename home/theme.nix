{ identity, pkgs, ... }:
let
  theme = import ../lib/theme.nix;
  c = theme.colors;
  ansi = with c; [
    surface1
    red
    green
    yellow
    blue
    pink
    teal
    subtext1
    surface2
    red
    green
    yellow
    blue
    pink
    teal
    text
  ];
  starship = (builtins.fromTOML (builtins.readFile ./starship.toml)) // {
    palette = "fleet";
    palettes.fleet = c // {
      cyan = c.teal;
      purple = c.mauve;
    };
  };
in
{
  hjem.users.${identity.username} = {
    files.".tmux.conf".text = ''
      set -g default-terminal "tmux-256color"
      set -as terminal-features ",xterm-ghostty:RGB"
      set -g status-style "bg=${c.mantle},fg=${c.text}"
      set -g message-style "bg=${c.surface0},fg=${c.mauve}"
      set -g pane-border-style "fg=${c.surface1}"
      set -g pane-active-border-style "fg=${c.mauve}"
      setw -g window-status-current-style "bg=${c.surface0},fg=${c.mauve},bold"
      set -g mode-style "bg=${c.surface1},fg=${c.text}"
    '';
    xdg.config.files = {
      "starship.toml".source = (pkgs.formats.toml { }).generate "starship-fleet.toml" starship;
      "ghostty/config.ghostty".text = ''
        theme = ${theme.name}
        font-family = ${theme.fonts.mono}
        font-size = ${toString theme.fonts.size}
        window-padding-x = 12
        window-padding-y = 12
        background-opacity = 0.96
        window-decoration = false
        gtk-single-instance = true
      '';
      "ghostty/themes/${theme.name}".text = ''
        background = ${c.base}
        foreground = ${c.text}
        cursor-color = ${c.rosewater}
        cursor-text = ${c.base}
        selection-background = ${c.surface2}
        selection-foreground = ${c.text}
      ''
      + pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.imap0 (i: color: "palette = ${toString i}=${color}") ansi
      )
      + "\n";
      "nvim/lua/plugins/theme.lua".source = pkgs.replaceVars ./nvim/lua/plugins/theme.lua {
        catppuccin = pkgs.vimPlugins.catppuccin-nvim;
        palette = builtins.toJSON c;
      };
    };
  };
}
