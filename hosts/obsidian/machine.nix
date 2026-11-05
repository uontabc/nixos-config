{ ... }:
{
  # Plan: approximately 512 GiB freed from C:, with 1 GiB NIXOS_BOOT (EA00)
  # and the remainder NIXOS_ROOT. Create these only in actual freed space.
  # Generate hardware separately with --no-filesystems; disko owns the mounts.
  # imports = [ ./hardware-configuration.nix ];
  fleet.storage.laptop = {
    rootPartition = null; # /dev/disk/by-partuuid/NEW-LINUX-ROOT-PARTUUID
    bootPartition = null; # /dev/disk/by-partuuid/NEW-XBOOTLDR-PARTUUID
    # Read from the current Windows GPT. Recheck in the installer before use.
    espPartition = "/dev/disk/by-partuuid/cbbc0255-bfca-41c2-913b-bc9ea08183cb";
  };
  assertions = [
    {
      assertion = false;
      message = "Laptop template: verify the freed Linux partitions and Windows ESP, import real hardware, and seed the persistent password hash before removing this installation guard.";
    }
  ];
}
