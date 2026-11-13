{ ... }:
{
  flake.modules.nixos.sing-box-reality =
    {
      config,
      lib,
      identity,
      ...
    }:
    let
      cfg = config.fleet.reality;
    in
    {
      options.fleet.reality = {
        enable = lib.mkEnableOption "the VLESS + REALITY proxy node";
        port = lib.mkOption {
          type = lib.types.port;
          default = 443;
        };
        handshakeHost = lib.mkOption { type = lib.types.str; };
        handshakePort = lib.mkOption {
          type = lib.types.port;
          default = 443;
        };
        secretDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/sing-box-secrets";
          description = "Directory of externally provisioned REALITY credentials; Nix never generates or rotates these files.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.sing-box = {
          enable = true;
          settings = {
            log = {
              level = "info";
              timestamp = true;
            };
            inbounds = [
              {
                type = "vless";
                tag = "vless-reality-in";
                listen = "::";
                listen_port = cfg.port;
                users = [
                  {
                    name = identity.username;
                    uuid._secret = "${cfg.secretDirectory}/uuid";
                    flow = "xtls-rprx-vision";
                  }
                ];
                tls = {
                  enabled = true;
                  server_name = cfg.handshakeHost;
                  reality = {
                    enabled = true;
                    handshake = {
                      server = cfg.handshakeHost;
                      server_port = cfg.handshakePort;
                    };
                    private_key._secret = "${cfg.secretDirectory}/private-key";
                    short_id = [ { _secret = "${cfg.secretDirectory}/short-id"; } ];
                  };
                };
              }
            ];
            outbounds = [
              {
                type = "direct";
                tag = "direct";
              }
            ];
            route.final = "direct";
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
        # Credentials are provisioned outside Nix and never enter the store.
        # Creating the directory does not create, replace or rotate any secrets.
        systemd.tmpfiles.settings."sing-box-secrets".${cfg.secretDirectory}.d = {
          mode = "0700";
          user = "root";
          group = "root";
        };
      };
    };
}
