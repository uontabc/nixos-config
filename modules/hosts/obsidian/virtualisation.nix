{
  flake.modules.nixos.obsidian =
    {
      config,
      identity,
      pkgs,
      ...
    }:
    let
      virsh = "${config.virtualisation.libvirtd.package}/bin/virsh --connect qemu:///system";
    in
    {
      programs.virt-manager.enable = true;

      virtualisation.libvirtd = {
        enable = true;
        # Never implicitly restart a VM that could take over the host GPU.
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          vhostUserPackages = [ pkgs.virtiofsd ];
          # The NixOS module exposes QEMU's bundled UEFI firmware by default.
        };
      };

      users.users.${identity.username}.extraGroups = [
        "libvirtd"
        "kvm"
      ];
      environment.systemPackages = with pkgs; [
        virt-viewer
        pciutils
      ];
      environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

      # Prepare PCI passthrough without claiming the desktop's only GPU.
      # Do not set vfio-pci.ids, blacklist NVIDIA, or stop the display manager.
      boot.kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
      ];
      boot.kernelModules = [
        "kvm-amd"
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];

      # Only expose DHCP and DNS to guests, not every service on the host.
      networking.firewall.interfaces.virbr0 = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [
          53
          67
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/libvirt/images 2770 qemu-libvirtd libvirtd - -"
      ];

      # The upstream module seeds the default NAT network, but does not enable
      # its autostart or create a storage pool. Preserve any existing definitions.
      systemd.services.libvirt-defaults = {
        description = "Initialize the default libvirt network and storage pool";
        wantedBy = [ "multi-user.target" ];
        requires = [ "libvirtd.service" ];
        after = [
          "libvirtd.service"
          "systemd-tmpfiles-setup.service"
        ];
        path = [ pkgs.gnugrep ];
        unitConfig.RequiresMountsFor = "/var/lib/libvirt";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # A new persistence bind mount can hide directories made by tmpfiles
          # earlier during nixos-rebuild switch. Ensure storage exists after it.
          ${pkgs.coreutils}/bin/install -d -m 2770 -o qemu-libvirtd -g libvirtd /var/lib/libvirt/images

          ${virsh} net-autostart default
          if ! ${virsh} net-list --name | grep -Fxq default; then
            ${virsh} net-start default
          fi

          if ! ${virsh} pool-info default >/dev/null 2>&1; then
            ${virsh} pool-define-as default dir --target /var/lib/libvirt/images
          fi
          ${virsh} pool-autostart default
          if ! ${virsh} pool-list --name | grep -Fxq default; then
            ${virsh} pool-start default
          fi
        '';
      };
    };
}
