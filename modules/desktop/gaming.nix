{
  flake.modules.nixos.gaming =
    { config, pkgs, ... }:
    {
      # Includes the Steam runtime, controller rules and 32-bit audio support.
      # Remote Play / LAN transfer firewall ports remain closed by default.
      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          extraProfile = ''
            # pressure-vessel hides /run/current-system, but keeps /nix/store visible.
            export XCURSOR_PATH="${pkgs.bibata-cursors}/share/icons''${XCURSOR_PATH:+:$XCURSOR_PATH}"
          '';
        };
        extraPackages = [
          config.programs.gamescope.package
          pkgs.bibata-cursors
        ];
        extraCompatPackages = [ pkgs.dwproton-bin ];
      };
      programs.gamescope = {
        enable = true;
        # Nested per-game use in niri; retain normal Vulkan/Steam library lookup.
        # A capability-wrapped binary can lose LD_* paths through secure-exec.
        capSysNice = false;
      };
    };
}
