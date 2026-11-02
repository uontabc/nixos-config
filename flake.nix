{
  description = "uontabc's NixOS profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    import-tree.url = "github:vic/import-tree";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixos-wsl = {
      # Track the WSL module compatible with nixos-unstable; flake.lock pins it.
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      # Only the NixOS persistence module is used; user files remain on hjem.
      inputs.home-manager.follows = "";
    };

    # Desktop projects retain their own pinned nixpkgs for their dependencies.
    mango.url = "github:mangowm/mango";
    pi.url = "github:lukasl-dev/pi.nix";
    vicinae.url = "github:vicinaehq/vicinae";
    noctalia.url = "github:noctalia-dev/noctalia";

    lazyvim = {
      url = "github:LazyVim/LazyVim";
      flake = false;
    };
    lazy-nvim = {
      url = "github:folke/lazy.nvim/stable";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake {
      inherit inputs;
    } (inputs.import-tree ./modules);
}
