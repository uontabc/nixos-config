{ ... }:
{
  flake.modules.nixos.laptop =
    { identity, pkgs, ... }:
    {
      boot.loader = {
        systemd-boot.enable = false;
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          # Keep kernels and initrds on the separate ext4 /boot, outside ZFS.
          copyKernels = true;
          configurationLimit = 5;
          useOSProber = false;
          theme = pkgs.minimal-grub-theme;
          default = 0;
          timeoutStyle = "menu";
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/efi";
        };
        timeout = 10;
      };

      # NixOS is the only OS on this disk; keep the hardware clock in UTC.
      time.hardwareClockInLocalTime = false;
      networking.networkmanager.enable = true;
      users.users.${identity.username}.extraGroups = [ "networkmanager" ];

      hardware.enableRedistributableFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
      };

      powerManagement.enable = true;
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
      services.fwupd.enable = true;
      services.libinput.enable = true;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };
}
