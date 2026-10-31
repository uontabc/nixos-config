{
  inputs,
  identity,
  pkgs,
  ...
}:
let
  # lazy.nvim updates its own helptags at runtime. Build that index once and
  # skip only that write when running the pinned, immutable Nix-store copy.
  lazyNvim =
    pkgs.runCommand "lazy-nvim-pinned"
      {
        nativeBuildInputs = [ pkgs.neovim-unwrapped ];
      }
      ''
        mkdir -p "$out"
        cp -R ${inputs.lazy-nvim}/. "$out/"
        chmod -R u+w "$out"
        substituteInPlace "$out/lua/lazy/help.lua" \
          --replace-fail 'if Config.plugins["lazy.nvim"] then' \
            'if Config.plugins["lazy.nvim"] and not Config.plugins["lazy.nvim"].dir:match("^/nix/store/") then'
        substituteInPlace "$out/lua/lazy/manage/task/plugin.lua" \
          --replace-fail 'return not plugin._.is_local and not plugin._.dirty' \
            'return plugin.dir:match("^/nix/store/") or (not plugin._.is_local and not plugin._.dirty)'
        export HOME="$TMPDIR"
        nvim --headless -u NONE -i NONE -c "helptags $out/doc" -c qa
      '';
  lazyVim =
    pkgs.runCommand "lazyvim-pinned"
      {
        nativeBuildInputs = [ pkgs.neovim-unwrapped ];
      }
      ''
        mkdir -p "$out"
        cp -R ${inputs.lazyvim}/. "$out/"
        chmod -R u+w "$out"
        export HOME="$TMPDIR"
        nvim --headless -u NONE -i NONE -c "helptags $out/doc" -c qa
      '';
in
{
  hjem.users.${identity.username} = {
    enable = true;
    # Manage individual files so plugin state and locks remain writable.
    files.".zshrc".source = pkgs.replaceVars ./zsh/interactive.zsh {
      history_guard = "${pkgs.python312}/bin/python3 ${./zsh/history-guard.py}";
      history_zsh = "${pkgs.zsh}/bin/zsh";
    };
    xdg.config.files = {
      "git/config".text = ''
        [user]
          name = ${identity.fullName}
          email = ${identity.email}
        [init]
          defaultBranch = main
        [pull]
          ff = only
        [push]
          autoSetupRemote = true
        [fetch]
          prune = true
        [core]
          editor = nvim
        [diff]
          algorithm = histogram
        [merge]
          conflictStyle = zdiff3
      '';
      "starship.toml".source = ./starship.toml;
      "nvim/init.lua".source = ./nvim/init.lua;
      "nvim/lua/config/lazy.lua".source = pkgs.replaceVars ./nvim/lua/config/lazy.lua {
        lazy_nvim = lazyNvim;
        lazyvim = lazyVim;
      };
      "nvim/lua/config/options.lua".source = ./nvim/lua/config/options.lua;
      "nvim/lua/config/keymaps.lua".source = ./nvim/lua/config/keymaps.lua;
      "nvim/lua/config/autocmds.lua".source = ./nvim/lua/config/autocmds.lua;
      "nvim/lua/plugins/development.lua".source = ./nvim/lua/plugins/development.lua;
    };
  };
}
