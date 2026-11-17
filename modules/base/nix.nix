{ inputs, ... }:
{
  flake.modules.nixos.nix =
    {
      lib,
      pkgs,
      hostKey,
      ...
    }:
    {
      # One name for the machine hostname, flake target and rebuild command.
      networking.hostName = hostKey;

      time.timeZone = lib.mkDefault "Asia/Shanghai";
      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
      documentation.doc.enable = lib.mkDefault false;

      # Expose community packages as pkgs.nur.repos.<maintainer>.<package>.
      # Adding the overlay does not install or eagerly evaluate every NUR repo.
      nixpkgs.overlays = [ inputs.nur.overlays.default ];
      nixpkgs.config.allowUnfree = true;
      nix = {
        # Replace the system Nix CLI and daemon with the stable Lix release.
        package = pkgs.lixPackageSets.stable.lix;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
          warn-dirty = false;
        };
        gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          options = lib.mkDefault "--delete-older-than 30d";
        };
      };

      # stateVersion, users, access, filesystems, networking, and hardware belong to
      # each host or an explicitly selected profile.
    };
}
