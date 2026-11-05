{
  identity,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../lib/theme.nix;
  c = theme.colors;
  accent = c.${theme.accent};
  fg = color: { fg = color; };
  badge = color: {
    fg = c.base;
    bg = color;
    bold = true;
  };
  border = fg c.surface2;
  selected = {
    fg = c.text;
    bg = c.surface1;
    bold = true;
  };
in
{
  # Imported only by onyx; the desktop keeps its own file manager.
  # nixpkgs' wrapper includes preview, archive, search and navigation helpers.
  environment.systemPackages = [ pkgs.yazi ];

  programs.zsh.interactiveShellInit = ''
    # Unlike a plain yazi invocation, y follows the directory selected on exit.
    function y() {
      local tmp cwd ret
      tmp="$(${pkgs.coreutils}/bin/mktemp -t yazi-cwd.XXXXXX)" || return
      ${lib.getExe pkgs.yazi} "$@" --cwd-file="$tmp"
      ret=$?
      if cwd="$(<"$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd" || ret=$?
      fi
      ${pkgs.coreutils}/bin/rm -f -- "$tmp"
      return "$ret"
    }
  '';

  hjem.users.${identity.username}.xdg.config.files."yazi/theme.toml".source =
    (pkgs.formats.toml { }).generate "yazi-${theme.name}.toml"
      {
        # Override the built-in theme directly: no runtime flavor downloads.
        app.overall = {
          fg = c.text;
          bg = c.base;
        };
        mgr = {
          cwd = fg accent;
          find_keyword = (fg c.yellow) // {
            bold = true;
            underline = true;
          };
          find_position = fg c.peach;
          marker_copied = {
            fg = c.green;
            bg = c.green;
          };
          marker_cut = {
            fg = c.red;
            bg = c.red;
          };
          marker_marked = {
            fg = c.teal;
            bg = c.teal;
          };
          marker_selected = {
            fg = accent;
            bg = accent;
          };
          count_copied = badge c.green;
          count_cut = badge c.red;
          count_selected = badge accent;
          border_style = border;
        };
        indicator = {
          parent = selected;
          current = selected;
          preview = (fg accent) // {
            underline = true;
          };
        };
        tabs = {
          active = badge accent;
          inactive = {
            fg = c.subtext0;
            bg = c.surface0;
          };
        };
        mode = {
          normal_main = badge accent;
          normal_alt = {
            fg = accent;
            bg = c.surface0;
          };
          select_main = badge c.green;
          select_alt = {
            fg = c.green;
            bg = c.surface0;
          };
          unset_main = badge c.red;
          unset_alt = {
            fg = c.red;
            bg = c.surface0;
          };
        };
        status = {
          overall = {
            fg = c.text;
            bg = c.mantle;
          };
          perm_sep = fg c.overlay0;
          perm_type = fg accent;
          perm_read = fg c.yellow;
          perm_write = fg c.red;
          perm_exec = fg c.green;
          progress_label = (fg c.text) // {
            bold = true;
          };
          progress_normal = {
            fg = accent;
            bg = c.surface1;
          };
          progress_error = {
            fg = c.red;
            bg = c.surface1;
          };
        };
        which = {
          inherit border;
          cand = fg accent;
          rest = fg c.overlay1;
          desc = fg c.text;
          separator_style = fg c.surface2;
        };
        confirm = {
          inherit border;
          title = fg accent;
          btn_yes = badge accent;
          btn_no = fg c.subtext0;
        };
        spot = {
          inherit border;
          title = fg accent;
          tbl_col = fg accent;
          tbl_cell = selected;
        };
        notify = {
          title_info = fg c.green;
          title_warn = fg c.yellow;
          title_error = fg c.red;
        };
        pick = {
          inherit border;
          active = (fg accent) // {
            bold = true;
          };
          inactive = fg c.subtext0;
        };
        input = {
          inherit border selected;
          title = fg accent;
          value = fg c.text;
        };
        cmp = {
          inherit border;
          active = selected;
          inactive = fg c.subtext0;
        };
        tasks = {
          inherit border;
          title = fg accent;
          hovered = selected;
        };
        help = {
          inherit border;
          chord = fg accent;
          action = fg c.text;
          hovered = selected;
        };
        filetype.rules = [
          {
            mime = "**/image/*";
            fg = c.yellow;
          }
          {
            mime = "**/{audio,video}/*";
            fg = c.pink;
          }
          {
            mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
            fg = c.peach;
          }
          {
            mime = "**/application/{pdf,doc,rtf}";
            fg = c.sky;
          }
          {
            mime = "vfs/{absent,stale}";
            fg = c.overlay0;
          }
          {
            url = "*";
            is = "orphan";
            fg = c.red;
          }
          {
            url = "*";
            is = "exec";
            fg = c.green;
          }
          {
            url = "*";
            is = "dummy";
            fg = c.red;
          }
          {
            url = "*/";
            is = "dummy";
            fg = c.red;
          }
          {
            url = "*/";
            fg = c.blue;
            bold = true;
          }
          {
            url = "*";
            fg = c.text;
          }
        ];
      };
}
