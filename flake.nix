{
  description = "uontabc's NixOS fleet — per-host systems and shared profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop projects retain their own pinned nixpkgs for their dependencies.
    mango.url = "github:mangowm/mango";
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

      nixosConfigurations = configurations // {
        # Compatibility for commands saved before the fleet layout.
        nixos = configurations.wsl;
      };

      devShells.${system} = import ./shells { inherit pkgs; };
      formatter.${system} = pkgs.nixfmt-tree;
    };
}
