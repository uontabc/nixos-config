{ self, ... }:
{
  hosts.obsidian = {
    system = "x86_64-linux";
    module =
      {
        inputs,
        pkgs,
        identity,
        ...
      }:
      {
        imports = with self.modules.nixos; [
          inputs.disko.nixosModules.disko
          desktop
          development
          laptop
        ];

        # Use the upstream release pin and unmodified kernel to retain cache hits.
        # NVIDIA's modules in graphics.nix are built against this same kernel set.
        nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
        boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
        nix.settings = {
          # 32 logical CPUs but only 16 GiB RAM: avoid multiplying heavy build jobs.
          max-jobs = 1;
          cores = 4;
          extra-substituters = [ "https://cache.lantian.pub/lantian" ];
          extra-trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
        };

        # VM Curator launches QEMU directly; no libvirt daemon is needed.
        # Hardware acceleration also requires SVM / AMD-V enabled in firmware.
        boot.kernelModules = [ "kvm-amd" ];
        users.users.${identity.username}.extraGroups = [ "kvm" ];
        environment.systemPackages = with pkgs; [
          vm-curator
          qemu
          e2fsprogs # chattr: VM Curator disables CoW for VM storage on Btrfs.
        ];

        zramSwap = {
          enable = true;
          algorithm = "zstd";
          memoryPercent = 100;
          priority = 100;
        };

        # Use only the existing zram swap; do not create disk-backed swap files.
        swapDevices = [ ];
        hardware.cpu.amd.updateMicrocode = true;
        # Fresh-install compatibility baseline; keep it after subsequent upgrades.
        system.stateVersion = "26.05";
      };
  };
}
