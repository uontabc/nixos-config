{
  flake.modules.nixos.kitty =
    {
      config,
      identity,
      lib,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      c = theme.colors;
      templates =
        config.hjem.users.${identity.username}.programs.noctalia.settings.theme.templates or { };
      useNoctaliaTheme =
        (templates.enable_builtin_templates or false) && lib.elem "kitty" (templates.builtin_ids or [ ]);
      # Tokyo Night's terminal ANSI palette (night variant).
      ansi = with c; [
        mantle
        red
        green
        yellow
        blue
        pink
        sky
        subtext1
        overlay1
        red
        green
        yellow
        blue
        pink
        sky
        text
      ];
    in
    {
      hjem.users.${identity.username}.xdg.config.files = {
        # The built-in hook touches kitty.conf even when the include already exists.
        "kitty/kitty.conf".type = lib.mkIf useNoctaliaTheme "copy";
        "kitty/kitty.conf".clobber = lib.mkIf useNoctaliaTheme true;
        "kitty/kitty.conf".permissions = lib.mkIf useNoctaliaTheme "0600";
        "kitty/kitty.conf".text = ''
          include themes/${theme.name}.conf
          ${lib.optionalString useNoctaliaTheme "include themes/noctalia.conf"}
          font_family ${theme.fonts.mono}
          font_size ${toString (theme.fonts.size + 1)}
          # Recursive is unpatched; render Nerd Font private-use icons separately.
          symbol_map U+E000-U+F8FF,U+F0000-U+FFFFD ${theme.fonts.symbols}
          # Smooth text-cursor trails, including single-cell movements.
          cursor_trail 3
          cursor_trail_decay 0.1 0.3
          cursor_trail_start_threshold 1
          window_padding_width 12
          background_opacity 1.0
          window_border_width 0
          draw_minimal_borders yes
          hide_window_decorations yes
          enable_audio_bell no
          confirm_os_window_close 0
          enabled_layouts splits,stack

          # Keep the previous terminal's split/navigation shortcuts.
          map ctrl+shift+o launch --location=vsplit --cwd=current
          map ctrl+shift+e launch --location=hsplit --cwd=current
          map ctrl+alt+left neighboring_window left
          map ctrl+alt+right neighboring_window right
          map ctrl+alt+up neighboring_window up
          map ctrl+alt+down neighboring_window down
          map ctrl+shift+enter toggle_layout stack
          # Handle tab switching here instead of passing Ctrl+T to shell/fzf.
          map ctrl+t next_tab
          map ctrl+shift+t new_tab_with_cwd
        '';
        "kitty/themes/${theme.name}.conf".text = ''
          background ${c.base}
          foreground ${c.text}
          cursor ${c.text}
          cursor_text_color ${c.base}
          selection_background ${c.selection}
          selection_foreground ${c.text}
          active_border_color ${c.${theme.accent}}
          inactive_border_color ${c.surface1}
          active_tab_background ${c.${theme.accent}}
          active_tab_foreground ${c.base}
          inactive_tab_background ${c.surface0}
          inactive_tab_foreground ${c.text}
        ''
        + lib.concatStringsSep "\n" (lib.imap0 (i: color: "color${toString i} ${color}") ansi)
        + "\n";
      };
    };
}
