{
  flake.modules.nixos.development-tools = { pkgs, ... }: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
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
