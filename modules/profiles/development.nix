{ pkgs, identity, ... }:
{
  imports = [
    ../development.nix
    ../../home
  ];

  users.users.${identity.username} = {
    isNormalUser = true;
    home = "/home/${identity.username}";
    description = identity.fullName;
    shell = pkgs.zsh;
    extraGroups = [
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
    tree
    tmux
    file
    which
    nixfmt
    nix-output-monitor
  ];
}
