{
  flake.modules.nixos.niri =
    {
      config,
      inputs,
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      theme = import ../../../lib/theme.nix;
      xwaylandSatellite = inputs.xwayland-satellite.packages.${pkgs.stdenv.hostPlatform.system}.default;
      noctalia = config.hjem.users.${identity.username}.programs.noctalia.package;
    in
    {
      programs.niri = {
        enable = true;
        # Reuse the official binary cache rather than building upstream Git.
        package = pkgs.niri;
        # GTK handles file selection; the GNOME portal handles screen sharing.
        useNautilus = false;
      };

      services.greetd = {
        enable = true;
        settings.default_session = {
          # Upstream niri-session loads the login shell and imports its environment.
          command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
          user = "greeter";
        };
      };
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      systemd.tmpfiles.settings."desktop-directories" = {
        "${config.users.users.${identity.username}.home}/Pictures/Screenshots".d = {
          mode = "0755";
          user = identity.username;
          group = config.users.users.${identity.username}.group;
        };
      };

      hjem.users.${identity.username} = {
        systemd.services.kanshi = {
          description = "Switch between external-only and laptop displays";
          wantedBy = [ "niri.service" ];
          partOf = [ "niri.service" ];
          after = [ "niri.service" ];
          enableDefaultPath = false;
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.kanshi} -c ${./kanshi.conf}";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
        xdg.config.files."niri/config.kdl".source = pkgs.replaceVars ./config.kdl {
          terminal = lib.getExe pkgs.kitty;
          file_manager = lib.getExe pkgs.pcmanfm;
          noctalia = lib.getExe noctalia;
          xwayland_satellite = lib.getExe xwaylandSatellite;
          recorder = lib.getExe config.programs.obs-studio.finalPackage;
          cursor_theme = theme.cursorName;
          cursor_size = toString theme.cursorSize;
          base = theme.colors.base;
        };
      };

      environment.systemPackages = [
        pkgs.wl-clipboard
        xwaylandSatellite
        pkgs.xdg-utils
      ];
    };
}
