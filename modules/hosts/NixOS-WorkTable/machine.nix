{
  flake.modules.nixos."NixOS-WorkTable" =
    { ... }:
    {
      # Fresh UEFI install: ERASE the entire 1 TB UMIS NVMe, including Windows
      # and the current NixOS installation. Recheck this ID in the live installer.
      # Disko owns all partitions and mounts; no generated hardware file needed.
      storage.laptop.disk = "/dev/disk/by-id/nvme-eui.5cdfb804b1a00b01";

      # Verified on this laptop: NVMe storage and USB controller/keyboard.
      # AMD microcode, KVM and NVIDIA are configured in the other host modules.
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
      ];

      # Stable, machine-specific ID required to import the ZFS root pool.
      networking.hostId = "4e2295dd";
    };
}
