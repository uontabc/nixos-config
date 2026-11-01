{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Windows currently exposes only the RTX 5060. PRIME offload is intentionally
  # unset until a live Linux boot confirms both GPUs and their actual PCI IDs.
  environment.sessionVariables.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
}
