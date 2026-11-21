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
            font_size ${toString (theme.fonts.size + 2)}
            # Keep the Latin font; use Noto's monospace CJK family for Chinese.
            symbol_map U+2E80-U+303F,U+31C0-U+31EF,U+3400-U+4DBF,U+4E00-U+9FFF,U+F900-U+FAFF,U+FE10-U+FE1F,U+FE30-U+FE4F,U+FF00-U+FFEF,U+20000-U+2FA1F,U+30000-U+323AF ${theme.fonts.cjkMono}
            # Render Nerd Font private-use icons separately from the text font.
            symbol_map U+E000-U+F8FF,U+F0000-U+FFFFD ${theme.fonts.symbols}
            # Smooth text-cursor trails, including single-cell movements.
            cursor_trail 3
            cursor_trail_decay 0.1 0.3
            cursor_trail_start_threshold 1
            window_padding_width 12
            background_opacity 1.0
            # Draw separators between splits, without an outer single-window border.
            window_border_width 2px
            # Noctalia's surface-colored inactive border is too faint on this palette.
            inactive_border_color ${c.overlay0}
            draw_minimal_borders yes
            hide_window_decorations yes
            enable_audio_bell no
            confirm_os_window_close 0
            enabled_layouts splits,stack

            # Numbered, stationary labels with a sliding rounded highlight.
            tab_bar_edge top
            tab_bar_style custom
            tab_bar_min_tabs 1
            tab_bar_align left
            # Cell zero is a hidden geometry beacon; Python adds the left inset.
            tab_bar_margin_width 0
            tab_bar_margin_height 6 0
            tab_bar_background none
            active_tab_font_style normal
            inactive_tab_font_style normal
            tab_separator ""
            tab_title_max_length 30
            tab_title_template " {fmt.fg.color8}{index}{fmt.fg.tab} {bell_symbol}{activity_symbol}{title.replace(' │ ', '·').replace(' · ', '·')} "
            custom_shaders active-tab-slide-lite

            # Keep split creation shortcuts; use Vim's H/J/K/L directions.
            map ctrl+shift+o launch --location=vsplit --cwd=current
            map ctrl+shift+e launch --location=hsplit --cwd=current
            map ctrl+alt+h neighboring_window left
            map ctrl+alt+j neighboring_window bottom
            map ctrl+alt+k neighboring_window top
            map ctrl+alt+l neighboring_window right
            # Equivalent arrow keys, plus cycling when no geometric neighbor exists.
            map ctrl+alt+left neighboring_window left
            map ctrl+alt+down neighboring_window bottom
            map ctrl+alt+up neighboring_window top
            map ctrl+alt+right neighboring_window right
            map ctrl+alt+tab next_window
            map ctrl+shift+enter toggle_layout stack
            # Handle tab switching here instead of passing Ctrl+T to shell/fzf.
            map ctrl+t next_tab
            map ctrl+shift+t new_tab_with_cwd
          '';
        })
        {
          file.xdg_config."kitty/tab_bar.py".source = ./kitty/tab_bar.py;
          file.xdg_config."kitty/shaders/active-tab-slide-lite.slang".source =
            ./kitty/shaders/active-tab-slide-lite.slang;
          file.xdg_config."kitty/shaders/active-tab-slide-lite.pipeline".source =
            ./kitty/shaders/active-tab-slide-lite.pipeline;
          file.xdg_config."kitty/themes/${theme.name}.conf".text = ''
            background ${c.base}
            foreground ${c.text}
            cursor ${c.text}
            cursor_text_color ${c.base}
            selection_background ${c.selection}
            selection_foreground ${c.text}
            url_color ${c.${theme.accent}}
            active_border_color ${c.${theme.accent}}
            inactive_border_color ${c.overlay0}
            active_tab_background ${c.${theme.accent}}
            active_tab_foreground ${c.base}
            inactive_tab_background ${c.base}
            inactive_tab_foreground ${c.text}
          ''
          + lib.concatStringsSep "\n" (lib.imap0 (i: color: "color${toString i} ${color}") ansi)
          + "\n";
        }
      ];
    };
}
