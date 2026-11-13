{
  flake.modules.nixos.obsidian =
    { ... }:
    {
      # Fresh UEFI install: ERASE the entire 1 TB UMIS NVMe, including Windows
      # and the current NixOS installation. Recheck this ID in the live installer.
      # Generate hardware with --no-filesystems; disko owns all mounts.
      # imports = [ ./_hardware-configuration.nix ];
      fleet.storage.laptop.disk = "/dev/disk/by-id/nvme-eui.5cdfb804b1a00b01";

      # Stable, machine-specific ID required to import the ZFS root pool.
      networking.hostId = "4e2295dd";
    };
}
