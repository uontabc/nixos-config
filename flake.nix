{
  description = "uontabc's NixOS profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Keep the kernel's own nixpkgs pin for patch compatibility and cache hits.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # niri uses the cached nixpkgs release; only the X11 bridge tracks upstream.
    xwayland-satellite = {
      url = "github:Supreeeme/xwayland-satellite";
      inputs.nixpkgs.follows = "nixpkgs";
      # Only needed by upstream's development shell, not the package.
      inputs.rust-overlay.follows = "";
    };

    pi.url = "github:lukasl-dev/pi.nix";
    noctalia.url = "github:noctalia-dev/noctalia";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the maintainer's own nixpkgs pin to match its Rayburst binary cache.
    rayburst-packages.url = "github:ccicnce113424/nix-packages";

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake {
      inherit inputs;
    } (inputs.import-tree ./modules);
}
