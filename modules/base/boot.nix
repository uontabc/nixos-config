{ ... }:
{
  flake.modules.nixos.laptop =
    { identity, pkgs, ... }:
    let
      theme = import ../../lib/theme.nix;
      c = theme.colors;
      accent = c.${theme.accent};
      grubTheme = pkgs.writeTextDir "theme.txt" ''
        # Minimal Tokyo Night menu; no wallpaper or external image assets.
        desktop-color: "${c.base}"
        title-text: "NixOS"
        title-color: "${accent}"
        message-color: "${c.text}"
        message-bg-color: "${c.base}"
        + boot_menu {
          left = 15%
          top = 30%
          width = 70%
          height = 45%
          item_color = "${c.text}"
          selected_item_color = "${accent}"
          item_height = 36
          item_spacing = 8
          icon_width = 0
          icon_height = 0
          item_icon_space = 0
        }
        + label {
          top = 85%
          left = 15%
          width = 70%
          align = "center"
          color = "${c.subtext0}"
          text = "Select a system and press Enter"
        }
      '';
    in
    {
      boot.loader = {
        systemd-boot.enable = false;
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          # Keep kernels and initrds on /boot, not the small shared Windows ESP.
          copyKernels = true;
          configurationLimit = 5;
          useOSProber = true;
          theme = grubTheme;
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/efi";
        };
        timeout = 5;
      };

      # Match the existing Windows local-time RTC convention for dual boot.
      time.hardwareClockInLocalTime = true;
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
