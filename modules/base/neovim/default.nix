{
  flake.modules.nixos.neovim =
    {
      inputs,
      identity,
      pkgs,
      ...
    }:
    let
      treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        p: with p; [
          bash
          c
          cpp
          diff
          json
          lua
          luadoc
          luap
          markdown
          markdown_inline
          nix
          printf
          python
          query
          regex
          rust
          toml
          vim
          vimdoc
          yaml
        ]
      );
      treesitterRuntime = pkgs.symlinkJoin {
        name = "neovim-project-parsers";
        paths = treesitter.dependencies;
      };

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
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
      # Manage individual files so plugin state and locks remain writable.
      hjem.users.${identity.username}.xdg.config.files = {
        "nvim/init.lua".source = ./init.lua;
        "nvim/lua/config/lazy.lua".source = pkgs.replaceVars ./lua/config/lazy.lua {
          lazy_nvim = lazyNvim;
          lazyvim = lazyVim;
        };
        "nvim/lua/config/options.lua".source = pkgs.replaceVars ./lua/config/options.lua {
          treesitter_runtime = treesitterRuntime;
        };
        "nvim/lua/config/keymaps.lua".source = ./lua/config/keymaps.lua;
        "nvim/lua/config/autocmds.lua".source = ./lua/config/autocmds.lua;
        "nvim/lua/plugins/development.lua".source = ./lua/plugins/development.lua;
        "nvim/lua/plugins/theme.lua".source = pkgs.replaceVars ./lua/plugins/theme.lua {
          tokyonight = pkgs.vimPlugins.tokyonight-nvim;
        };
      };
    };
}
