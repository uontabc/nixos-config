{ lib, hostKey, ... }:
{
  imports = [ ./management.nix ];

  # One name for the machine hostname, flake target and rebuild command.
  networking.hostName = hostKey;

  time.timeZone = lib.mkDefault "Asia/Shanghai";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  documentation.doc.enable = lib.mkDefault false;

  nixpkgs.config.allowUnfree = true;
  nix = {
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
}
