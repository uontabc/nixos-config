{ pkgs, identity, ... }:
{
  wsl = {
    enable = true;
    defaultUser = identity.username;
    useWindowsDriver = true;
    wslConf.automount.options = "metadata,uid=1000,gid=100,umask=022";
  };

  networking.hostName = "nixos";
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keep man pages, omit bulky offline HTML documentation in this WSL image.
  documentation.doc.enable = false;

  users.users.${identity.username} = {
    uid = 1000;
    home = "/home/${identity.username}";
    description = identity.fullName;
    shell = pkgs.zsh;
    extraGroups = [
      "video"
      "render"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      # Only root is trusted by default; wheel membership does not grant Nix trust.
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
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
    NH_FLAKE = "/etc/nixos";
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
    (writeShellApplication {
      name = "rebuild";
      runtimeInputs = [ nixos-rebuild ];
      text = ''
        exec sudo nixos-rebuild switch --flake /etc/nixos#nixos "$@"
      '';
    })
  ];
}
