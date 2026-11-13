{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  perSystem =
    {
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      # Preserve the repository's package policy instead of using legacyPackages.
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      apps = {
        disko = {
          type = "app";
          program = "${inputs'.disko.packages.default}/bin/disko";
          meta.description = "Declarative disk partitioning and formatting with Disko";
        };
        nixos-anywhere = {
          type = "app";
          program = "${pkgs.nixos-anywhere}/bin/nixos-anywhere";
          meta.description = "Install NixOS on remote machines over SSH";
        };
      };

      formatter = pkgs.nixfmt-tree;
    };
}
