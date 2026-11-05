{
  config,
  inputs,
  identity,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.fleet.storage.laptop;
  ready = cfg.rootPartition != null && cfg.bootPartition != null && cfg.espPartition != null;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  config = lib.mkIf ready {
    boot.initrd.systemd = {
      services.reset-btrfs-root = {
        description = "Recreate only the ephemeral Btrfs root subvolume";
        requiredBy = [ "sysroot.mount" ];
        before = [ "sysroot.mount" ];
        requires = [ "${utils.escapeSystemdPath cfg.rootPartition}.device" ];
        after = [
          "${utils.escapeSystemdPath cfg.rootPartition}.device"
          "local-fs-pre.target"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        path = with pkgs; [
          bash
          btrfs-progs
          util-linux
          coreutils
        ];
        script = ''
          exec ${pkgs.bash}/bin/bash ${../../scripts/reset-btrfs-root.sh} \
            ${lib.escapeShellArg cfg.rootPartition} ${lib.escapeShellArg identity.username}
        '';
      };
    };

    # The entire /home and /nix are separate persistent subvolumes, not binds.
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/lib/nixos"
        "/var/lib/hjem"
        "/var/lib/systemd"
        "/var/lib/docker"
        "/var/lib/containerd"
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
      ];
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
}
