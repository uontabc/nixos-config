{
  flake.modules.nixos."NixOS-WorkTable" =
    {
      config,
      inputs,
      identity,
      lib,
      ...
    }:
    let
      cfg = config.storage.laptop;
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
            requires = [ "zfs-import-ontario.service" ];
            after = [ "zfs-import-ontario.service" ];
            unitConfig = {
              DefaultDependencies = false;
              # Never reset an already mounted root, even if the unit is restarted.
              ConditionPathIsMountPoint = "!/sysroot";
            };
            serviceConfig = {
              Type = "oneshot";
              # initrd-parse-etc reloads units and requests the mount graph again.
              # Stay active so a second start cannot roll back live mountpoints.
              RemainAfterExit = true;
              # No recursive/force flags: only root is reset; unexpected newer
              # snapshots stop boot rather than being destroyed automatically.
              ExecStart = "${config.boot.zfs.package}/bin/zfs rollback ontario/root@blank";
            };
          };
        };

        # The entire /home and /nix are separate persistent datasets, not binds.
        # nix-maid keeps its state in the persistent user's ~/.local/state.
        environment.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/nixos"
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
          hashedPasswordFile = "/persist/secrets/password";
        };
      };
    };
}
