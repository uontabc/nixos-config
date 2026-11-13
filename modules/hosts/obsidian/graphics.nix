{
  flake.modules.nixos.obsidian =
    { config, lib, ... }:
    let
      nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;
      # Linux production release corresponding to Windows 621.14. Keep this fallback
      # until nixpkgs.latest catches up; then follow newer packaged releases again.
      currentDriver = nvidiaPackages.mkDriver {
        version = "620.70.06";
        sha256_64bit = "sha256-KRGOOr0IwHVZvMo9nHYjjQOUkK8DYqLlvPy+cgSv1LE=";
        openSha256 = "sha256-dV8vzniUl3UJoG2Q3KdoUJigLRuQeTniUfB670gb1Mw=";
        settingsSha256 = "sha256-CFBRmXFJ9eAf5BRlHMBolahz1Pshr9giI7zcZC29oZ8=";
        persistencedSha256 = "sha256-FpGzhArrvR1nEt8lKDzNEnbvHvGP36gL1dINvpDAkpA=";
      };
    in
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Steam / Proton also need 32-bit OpenGL and Vulkan drivers.
      };
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Blackwell (RTX 5060 Laptop) requires NVIDIA's open kernel modules.
        open = true;
        modesetting.enable = true;
        powerManagement.enable = true;
        nvidiaSettings = true;
        package =
          if lib.versionAtLeast nvidiaPackages.latest.version currentDriver.version then
            nvidiaPackages.latest
          else
            currentDriver;
      };

      # Dedicated-GPU setup: use discrete-only / dGPU mode in firmware if available.
      # No PRIME offload, sync, reverse sync or GPU Bus IDs are configured.
      # Let NixOS and Steam manage library paths; do not force a global LD_LIBRARY_PATH.
    };
}
