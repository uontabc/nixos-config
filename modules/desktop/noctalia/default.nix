{
  flake.modules.nixos.noctalia =
    {
      inputs,
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      upstream = pkgs.noctalia;
      # Keep the cached release, but isolate GUI dependencies from project runtimes.
      noctalia = pkgs.symlinkJoin {
        name = "noctalia-${upstream.version}";
        version = upstream.version;
        paths = [ upstream ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/noctalia" --unset LD_LIBRARY_PATH
        '';
        meta = upstream.meta;
      };
    in
    {
      security.pam.services.noctalia = { };
      systemd.user.services.niri-lock-before-sleep = {
        description = "Lock Noctalia before suspending the niri session";
        wantedBy = [ "niri.service" ];
        partOf = [ "niri.service" ];
        after = [ "noctalia.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.swayidle}/bin/swayidle -w before-sleep '${lib.getExe noctalia} msg session lock'";
          Restart = "on-failure";
        };
      };

      hjem.extraModules = [ inputs.noctalia.hjemModules.default ];
      hjem.users.${identity.username} = {
        # Release 5.4.1 does not send READY=1. Upstream's Type=notify would restart
        # an otherwise healthy shell every 90 seconds.
        systemd.services.noctalia.serviceConfig = {
          Type = lib.mkForce "exec";
          RestartSec = 2;
        };
        programs.noctalia = {
          enable = true;
          package = noctalia;
          systemd = {
            enable = true;
            target = "niri.service";
          };
          # GUI overrides, schema markers and private state remain app-owned.
          settings = import ./_settings { inherit identity; };
        };
      };
    };
}
