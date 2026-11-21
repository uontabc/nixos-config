{ self, ... }:
{
  hosts."NixOS-WorkTable" = {
    system = "x86_64-linux";
    module =
      {
        config,
        inputs,
        lib,
        pkgs,
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
        # Use the upstream's matching patched ZFS, not stock ZFS (which marks
        # this newer kernel unsupported). Userland and module stay in sync.
        boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;

        # On this kernel/ZFS stack, ProtectHome=true fails to mask /home with
        # 226/NAMESPACE. A read-only tmpfs still hides home directories without
        # disabling the rest of each service's sandbox (already used by logind).
        systemd.services =
          lib.genAttrs
            [
              "bluetooth"
              "polkit"
              "power-profiles-daemon"
              "systemd-logind"
              "systemd-oomd"
              "systemd-timesyncd"
              "upower"
            ]
            (_: {
              serviceConfig.ProtectHome = "tmpfs";
            });

        nix.settings = {
          # 32 logical CPUs but only 16 GiB RAM: avoid multiplying heavy build jobs.
          max-jobs = 1;
          cores = 4;
          extra-substituters = [ "https://cache.lantian.pub/lantian" ];
          extra-trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
        };

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
