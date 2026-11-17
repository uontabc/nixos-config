# Noctalia's upstream user module targets Hjem; keep the same interface on nix-maid.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.noctalia;
  toml = pkgs.formats.toml { };
  json = pkgs.formats.json { };
  rawConfig = toml.generate "config.toml" cfg.settings;
  configToml =
    if cfg.validateConfig then
      pkgs.runCommand "noctalia-config" { } ''
        ${lib.getExe cfg.package} config validate ${rawConfig}
        cp ${rawConfig} $out
      ''
    else
      rawConfig;
  paletteFiles = lib.mapAttrs (
    name: palette: json.generate "${name}-palette.json" palette
  ) cfg.customPalettes;
in
{
  _class = "maid";

  options.programs.noctalia = {
    enable = lib.mkEnableOption "Noctalia";
    package = lib.mkOption {
      type = lib.types.package;
      description = "The Noctalia package to install and run.";
    };
    validateConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Validate the generated TOML configuration at build time.";
    };
    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = "Settings written to $XDG_CONFIG_HOME/noctalia/config.toml.";
    };
    customPalettes = lib.mkOption {
      type = json.type;
      default = { };
      description = "Custom palettes written to $XDG_CONFIG_HOME/noctalia/palettes.";
    };
    systemd = {
      enable = lib.mkEnableOption "the Noctalia user service";
      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        description = "The systemd user target that starts Noctalia.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ cfg.package ];

    file.xdg_config = lib.mkMerge [
      (lib.mkIf (cfg.settings != { }) {
        "noctalia/config.toml".source = configToml;
      })
      (lib.mapAttrs' (
        name: source: lib.nameValuePair "noctalia/palettes/${name}.json" { inherit source; }
      ) paletteFiles)
    ];

    systemd.services.noctalia = lib.mkIf cfg.systemd.enable {
      description = "Noctalia - A lightweight Wayland shell and bar";
      documentation = [ "https://docs.noctalia.dev/noctalia/" ];
      partOf = [ cfg.systemd.target ];
      after = [ cfg.systemd.target ];
      before = lib.remove cfg.systemd.target [ "graphical-session.target" ];
      wantedBy = [ cfg.systemd.target ];
      # Preserve the PATH imported by niri rather than replacing it with defaults.
      enableDefaultPath = false;
      restartTriggers = [
        cfg.package
      ]
      ++ lib.optional (cfg.settings != { }) configToml
      ++ lib.attrValues paletteFiles;
      serviceConfig = {
        Type = "notify";
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };
  };
}
