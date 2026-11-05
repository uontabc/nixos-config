{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.fleet.storage.laptop;
  ready = cfg.rootPartition != null && cfg.bootPartition != null && cfg.espPartition != null;
  partition = lib.types.nullOr lib.types.str;
  mountOptions = [
    "compress=zstd:3"
    "noatime"
  ];
  check = device: label: fs: ''
    ${pkgs.bash}/bin/bash ${../../scripts/check-linux-partition.sh} \
      ${lib.escapeShellArg device} ${label} ${fs}
  '';
in
{
  options.fleet.storage.laptop = {
    rootPartition = lib.mkOption {
      type = partition;
      default = null;
      description = "PARTUUID path of the new NIXOS_ROOT partition, never the whole Windows disk.";
    };
    bootPartition = lib.mkOption {
      type = partition;
      default = null;
      description = "PARTUUID path of the new 1 GiB NIXOS_BOOT XBOOTLDR partition.";
    };
    espPartition = lib.mkOption {
      type = partition;
      default = null;
      description = "PARTUUID path of the existing Windows EFI partition; mounted without formatting.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = ready;
          message = "Laptop disko: fill rootPartition, bootPartition and espPartition after preparing the Linux-only area in the Windows disk's free space.";
        }
        {
          assertion =
            !ready
            || (
              builtins.all (p: lib.hasPrefix "/dev/disk/by-partuuid/" p) [
                cfg.rootPartition
                cfg.bootPartition
                cfg.espPartition
              ]
              &&
                builtins.length (
                  lib.unique [
                    cfg.rootPartition
                    cfg.bootPartition
                    cfg.espPartition
                  ]
                ) == 3
            );
          message = "Laptop disko requires three different partition PARTUUID paths; whole-disk paths are not accepted.";
        }
      ];
    }
    (lib.mkIf ready {
      # No GPT/table node: this configuration never repartitions the Windows disk.
      disko.devices = {
        disk = {
          linuxRoot = {
            type = "disk";
            device = cfg.rootPartition;
            destroy = false;
            content = {
              type = "btrfs";
              preCreateHook = check cfg.rootPartition "NIXOS_ROOT" "btrfs";
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  inherit mountOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  inherit mountOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  inherit mountOptions;
                };
                "@persist" = {
                  mountpoint = "/persist";
                  inherit mountOptions;
                };
              };
            };
          };
          linuxBoot = {
            type = "disk";
            device = cfg.bootPartition;
            destroy = false;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
              preCreateHook = check cfg.bootPartition "NIXOS_BOOT" "vfat";
            };
          };
        };
        # nodev generates mounts, with no create/format operation for this device.
        nodev."/efi" = {
          device = cfg.espPartition;
          fsType = "vfat";
          mountOptions = [ "umask=0077" ];
        };
      };
      fileSystems."/home".neededForBoot = true;
      fileSystems."/nix".neededForBoot = true;
      fileSystems."/persist".neededForBoot = true;
    })
  ];
}
