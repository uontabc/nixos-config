{
  flake.modules.nixos.kitty =
    {
      config,
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../lib/theme.nix;
      c = theme.colors;
      configFile = import ../../lib/maid-config-file.nix { inherit pkgs; };
      templates =
        config.users.users.${identity.username}.maid.programs.noctalia.settings.theme.templates or { };
      useNoctaliaTheme =
        (templates.enable_builtin_templates or false) && lib.elem "kitty" (templates.builtin_ids or [ ]);
      # Preserve all 16 upstream ANSI colors, including the bright variants.
      ansi = theme.ansi;
    in
    {
      users.users.${identity.username}.maid = lib.mkMerge [
        (configFile {
          path = "kitty/kitty.conf";
          # The built-in hook touches kitty.conf even when the include already exists.
          writable = useNoctaliaTheme;
          text = ''
            include themes/${theme.name}.conf
            ${lib.optionalString useNoctaliaTheme "include themes/noctalia.conf"}
            font_family ${theme.fonts.mono}
            font_size ${toString (theme.fonts.size + 1)}
            # Keep Latin code unchanged; use Source Han Sans for Chinese.
            symbol_map U+2E80-U+303F,U+31C0-U+31EF,U+3400-U+4DBF,U+4E00-U+9FFF,U+F900-U+FAFF,U+FE10-U+FE1F,U+FE30-U+FE4F,U+FF00-U+FFEF,U+20000-U+2FA1F,U+30000-U+323AF ${theme.fonts.cjkMono}
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
        })
        {
          file.xdg_config."kitty/themes/${theme.name}.conf".text = ''
            background ${c.base}
            foreground ${c.text}
            cursor ${c.text}
            cursor_text_color ${c.base}
            selection_background ${c.selection}
            selection_foreground ${c.text}
            url_color ${c.${theme.accent}}
            active_border_color ${c.${theme.accent}}
            inactive_border_color ${c.surface1}
            active_tab_background ${c.${theme.accent}}
            active_tab_foreground ${c.base}
            inactive_tab_background ${c.surface0}
            inactive_tab_foreground ${c.text}
          ''
          + lib.concatStringsSep "\n" (lib.imap0 (i: color: "color${toString i} ${color}") ansi)
          + "\n";
        }
      ];
    };
}
