{ lib, identity, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    timeout = 5;
  };

  # Match the existing Windows local-time RTC convention for dual boot.
  time.hardwareClockInLocalTime = true;
  networking.networkmanager.enable = true;
  users.users.${identity.username}.extraGroups = [ "networkmanager" ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
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
