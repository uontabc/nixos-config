{ identity, pkgs, ... }:
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
      theme = pkgs.sleek-grub-theme.override { withStyle = "light"; };
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
}
