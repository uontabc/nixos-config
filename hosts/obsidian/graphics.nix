{ config, ... }:
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
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Dedicated-GPU setup: use discrete-only / dGPU mode in firmware if available.
  # No PRIME offload, sync, reverse sync or GPU Bus IDs are configured.
  # Let NixOS and Steam manage library paths; do not force a global LD_LIBRARY_PATH.
}
