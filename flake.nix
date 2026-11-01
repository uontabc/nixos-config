{
  description = "uontabc's NixOS profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      identity = {
        username = "uontabc";
        fullName = "uontabc";
        email = "uontabc@gmail.com";
      };
      hosts = import ./hosts;
      mkHost = import ./lib/mk-host.nix { inherit inputs identity; };
      configurations = nixpkgs.lib.mapAttrs mkHost hosts;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      lib.mkHost = mkHost;
      apps = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (targetSystem: {
        disko = {
          type = "app";
          program = "${inputs.disko.packages.${targetSystem}.default}/bin/disko";
        };
        nixos-anywhere = {
          type = "app";
          program = "${nixpkgs.legacyPackages.${targetSystem}.nixos-anywhere}/bin/nixos-anywhere";
        };
      });

      nixosConfigurations = configurations;

      devShells.${system} = import ./shells { inherit pkgs; };
      formatter.${system} = pkgs.nixfmt-tree;

      templates = {
        python = {
          path = ./templates/python;
          description = "python project with pinned dependencies and direnv";
        };
        rust = {
          path = ./templates/rust;
          description = "rust project with pinned dependencies and direnv";
        };
        cpp = {
          path = ./templates/cpp;
          description = "cpp project with pinned dependencies and direnv";
        };
      };
    };
}
