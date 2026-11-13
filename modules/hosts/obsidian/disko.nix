{
  flake.modules.nixos.obsidian =
    { config, lib, ... }:
    let
      cfg = config.fleet.storage.laptop;
      ready = cfg.disk != null;
    in
    {
      options.fleet.storage.laptop.disk = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Whole disk to ERASE for the ZFS reinstall; use its verified /dev/disk/by-id path.";
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = ready;
              message = "Laptop disko: set fleet.storage.laptop.disk to the verified whole disk. All partitions, including Windows and the current NixOS installation, will be erased.";
            }
            {
              assertion =
                !ready
                || (
                  lib.hasPrefix "/dev/disk/by-id/" cfg.disk
                  && builtins.match "/dev/disk/by-id/[^/]+" cfg.disk != null
                  && builtins.match ".*-part[0-9]+" cfg.disk == null
                );
              message = "Laptop disko requires a whole-disk /dev/disk/by-id path, not a partition path.";
            }
          ];
        }
        (lib.mkIf ready {
          disko.devices = {
            disk.system = {
              type = "disk";
              device = cfg.disk;
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    priority = 1;
                    size = "1G";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/efi";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  boot = {
                    priority = 2;
                    size = "2G";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/boot";
                    };
                  };
                  zfs = {
                    priority = 3;
                    size = "100%";
                    type = "BF01";
                    content = {
                      type = "zfs";
                      pool = "rpool";
                    };
                  };
                };
              };
            };
            zpool.rpool = {
              type = "zpool";
              options = {
                ashift = "12";
                autotrim = "on";
                cachefile = "none";
              };
              rootFsOptions = {
                mountpoint = "none";
                compression = "zstd";
                atime = "off";
                acltype = "posixacl";
                xattr = "sa";
                "com.sun:auto-snapshot" = "false";
              };
              # Siblings, not children of root: rolling back root must never
              # affect home, the Nix store, or the impermanence state.
              datasets = {
                root = {
                  type = "zfs_fs";
                  mountpoint = "/";
                  options.mountpoint = "legacy";
                  postCreateHook = ''
                    if ! zfs list -H -t snapshot -o name rpool/root@blank >/dev/null 2>&1; then
                      zfs snapshot rpool/root@blank
                    fi
                  '';
                };
                home = {
                  type = "zfs_fs";
                  mountpoint = "/home";
                  options.mountpoint = "legacy";
                };
                nix = {
                  type = "zfs_fs";
                  mountpoint = "/nix";
                  options.mountpoint = "legacy";
                };
                persist = {
                  type = "zfs_fs";
                  mountpoint = "/persist";
                  options.mountpoint = "legacy";
                };
              };
            };
          };

          boot.initrd.availableKernelModules = [ "nvme" ];
          boot.supportedFilesystems = [ "zfs" ];
          boot.zfs.forceImportRoot = false;
          services.zfs.autoScrub = {
            enable = true;
            pools = [ "rpool" ];
          };
          fileSystems."/home".neededForBoot = true;
          fileSystems."/nix".neededForBoot = true;
          fileSystems."/persist".neededForBoot = true;
        })
      ];
    };
}
