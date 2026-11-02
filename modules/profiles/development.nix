{ self, ... }:
{
  flake.modules.nixos.development =
    { pkgs, identity, ... }:
    {
      imports = [
        self.modules.nixos.editor
        self.modules.nixos.docker
        self.modules.nixos.pi
        ../../home
      ];

      users.users.${identity.username} = {
        isNormalUser = true;
        home = "/home/${identity.username}";
        description = identity.fullName;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "video"
          "render"
        ];
      };

      programs = {
        zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestions.enable = true;
          syntaxHighlighting.enable = true;
          promptInit = "";
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
        };
      };

      environment.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      environment.systemPackages = with pkgs; [
        git
        git-lfs
        lazygit
        curl
        wget
        jq
        unzip
        zip
        ripgrep
        fd
        fzf
        bat
        eza
        zoxide
        starship
        btop
        fastfetch
        tree
        file
        which
        nixfmt
        nix-output-monitor
      ];
    };
}
