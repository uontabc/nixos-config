# Runtime single-GPU passthrough support for VM Curator.
{
  flake.modules.nixos.obsidian =
    { ... }:
    {
      # Enable the AMD IOMMU; use passthrough mappings for host-owned devices.
      boot.kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
      ];

      # Load VFIO during normal boot. NVIDIA keeps the GPU until VM Curator's
      # single-gpu-start.sh explicitly unbinds it and attaches it to vfio-pci.
      # Do not set vfio-pci device IDs or blacklist the host NVIDIA driver.
      boot.kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];

      boot.extraModprobeConfig = ''
        # Load VFIO before NVIDIA without claiming the GPU at boot.
        softdep nvidia pre: vfio-pci
        # Disable legacy VGA access and idle D3 transitions while VFIO owns it.
        options vfio_pci disable_vga=1 disable_idle_d3=1
      '';
    };
}
