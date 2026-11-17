{
  flake.modules.nixos.neovim =
    { identity, pkgs, ... }:
    let
      # Nix supplies native parsers and their queries; vim.pack manages Lua plugins.
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
    in
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      # Explorer deletes go to the desktop trash rather than permanent removal.
      environment.systemPackages = [ pkgs.trash-cli ];

      # Individual links leave the directory (and vim.pack's lockfile) writable.
      users.users.${identity.username}.maid.file.xdg_config = {
        "nvim/init.lua".source = pkgs.replaceVars ./init.lua {
          treesitter = treesitter;
          treesitter_runtime = treesitterRuntime;
          pack_lock = ./nvim-pack-lock.snapshot.json;
        };
        "nvim/lua/options.lua".source = ./lua/options.lua;
        "nvim/lua/mappings.lua".source = ./lua/mappings.lua;
        "nvim/lua/autocmds.lua".source = ./lua/autocmds.lua;
        "nvim/lua/configs/lspconfig.lua".source = ./lua/configs/lspconfig.lua;
        "nvim/lua/plugins/init.lua".source = ./lua/plugins/init.lua;
        # Pinned upstream theme files; no runtime theme download required.
        "nvim/colors/bluney.vim".source = ../../../lib/themes/bluney/colors/bluney.vim;
        "nvim/colors/bluney-light.vim".source = ../../../lib/themes/bluney/colors/bluney-light.vim;
      };
    };
}
