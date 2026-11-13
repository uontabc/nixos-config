{
  flake.modules.nixos.obsidian =
    {
      config,
      inputs,
      identity,
      lib,
      ...
    }:
    let
      cfg = config.fleet.storage.laptop;
      ready = cfg.disk != null;
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      config = lib.mkIf ready {
        boot.initrd.systemd = {
          services.rollback-root = {
            description = "Roll back the ephemeral ZFS root dataset";
            requiredBy = [ "sysroot.mount" ];
            before = [ "sysroot.mount" ];
            requires = [ "zfs-import-rpool.service" ];
            after = [ "zfs-import-rpool.service" ];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "oneshot";
              # No recursive/force flags: only root is reset; unexpected newer
              # snapshots stop boot rather than being destroyed automatically.
              ExecStart = "${config.boot.zfs.package}/bin/zfs rollback rpool/root@blank";
            };
          };
        };

        # The entire /home and /nix are separate persistent datasets, not binds.
        environment.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/nixos"
            "/var/lib/hjem"
            "/var/lib/systemd"
            "/var/lib/fwupd"
            "/var/lib/upower"
            "/var/log"
            {
              directory = "/var/lib/NetworkManager";
              mode = "0700";
            }
            {
              directory = "/etc/NetworkManager/system-connections";
              mode = "0700";
            }
            {
              directory = "/var/lib/bluetooth";
              mode = "0700";
            }
          ]
          ++ lib.optional config.virtualisation.libvirtd.enable "/var/lib/libvirt";
          files = [ "/etc/machine-id" ];
        };

        # Seed this hash on the target's /persist before nixos-install. No passwords
        # or hashes are embedded in the repository or Nix store.
        users.mutableUsers = false;
        users.users.${identity.username} = {
          uid = 1000;
          hashedPasswordFile = "/persist/secrets/${identity.username}-password";
        };
      };
    };
}
