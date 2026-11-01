{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.fleet.storage.vps;
  ready = cfg.disk != null && cfg.firmware != null;
in
{
  options.fleet.storage.vps = {
    disk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Whole disk to erase for the future VPS reinstall; prefer its verified /dev/disk/by-id path.";
    };
    firmware = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "uefi"
          "bios"
        ]
      );
      default = null;
      description = "Firmware mode verified in the VPS rescue environment.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = ready;
          message = "VPS disko: choose the verified whole disk and firmware (uefi or bios) before preparing the reinstall.";
        }
        {
          assertion = cfg.disk == null || lib.hasPrefix "/dev/" cfg.disk;
          message = "VPS disko requires an explicit /dev/ block device path.";
        }
        {
          assertion = cfg.firmware != "bios" || pkgs.stdenv.hostPlatform.isx86;
          message = "The VPS BIOS template is for x86; ARM VPSs require a provider-supported UEFI or custom boot configuration.";
        }
      ];
      boot.loader.grub.enable = lib.mkDefault false;
    }
    (lib.mkIf ready {
      disko.devices.disk.system = {
        type = "disk";
        device = cfg.disk;
        content = {
          type = "gpt";
          partitions =
            (lib.optionalAttrs (cfg.firmware == "bios") {
              bios = {
                size = "1M";
                type = "EF02";
                priority = 1;
              };
            })
            // (lib.optionalAttrs (cfg.firmware == "uefi") {
              ESP = {
                size = "1G";
                type = "EF00";
                priority = 1;
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
            })
            // {
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
        };
      };
      boot.loader.grub = {
        enable = true;
        devices = lib.mkForce (if cfg.firmware == "bios" then [ cfg.disk ] else [ "nodev" ]);
        efiSupport = cfg.firmware == "uefi";
        efiInstallAsRemovable = cfg.firmware == "uefi";
      };
      boot.loader.efi.canTouchEfiVariables = false;
    })
  ];
}
