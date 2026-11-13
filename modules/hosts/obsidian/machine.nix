{
  flake.modules.nixos.obsidian =
    { ... }:
    {
      # Plan: approximately 512 GiB freed from C:, with 1 GiB NIXOS_BOOT (EA00)
      # and the remainder NIXOS_ROOT. Create these only in actual freed space.
      # Generate hardware separately with --no-filesystems; disko owns the mounts.
      # imports = [ ./_hardware-configuration.nix ];
      fleet.storage.laptop = {
        rootPartition = "/dev/disk/by-partuuid/8a971681-e394-4e57-8e84-95458f2fac9e"; # /dev/disk/by-partuuid/NEW-LINUX-ROOT-PARTUUID
        bootPartition = "/dev/disk/by-partuuid/68664f45-e2a5-45c6-b5be-e47719bea3e6"; # /dev/disk/by-partuuid/NEW-XBOOTLDR-PARTUUID
        # Read from the current Windows GPT. Recheck in the installer before use.
        espPartition = "/dev/disk/by-partuuid/21a6b870-0371-414e-9416-d91ca0f3732b";
      };
      assertions = [
        {
          assertion = true;
          message = "Laptop template: verify the freed Linux partitions and Windows ESP, import real hardware, and seed the persistent password hash before removing this installation guard.";
        }
      ];
    };
}
