{
  flake.modules.nixos.gaming =
    { config, ... }:
    {
      # Includes the Steam runtime, controller rules and 32-bit audio support.
      # Remote Play / LAN transfer firewall ports remain closed by default.
      programs.steam = {
        enable = true;
        extraPackages = [ config.programs.gamescope.package ];
      };
      programs.gamescope = {
        enable = true;
        # Nested per-game use in niri; retain normal Vulkan/Steam library lookup.
        # A capability-wrapped binary can lose LD_* paths through secure-exec.
        capSysNice = false;
      };
    };
}
