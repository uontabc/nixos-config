{
  description = "uontabc's NixOS-WSL workstation — systems, tools, and home";

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
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs identity; };
        modules = [
          inputs.nixos-wsl.nixosModules.default
          inputs.hjem.nixosModules.default
          ./configuration.nix
        ];
      };

      devShells.${system} = import ./shells { inherit pkgs; };
      formatter.${system} = pkgs.nixfmt-tree;
    };
}
