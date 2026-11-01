{
  config,
  identity,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../../lib/theme.nix;
  c = theme.colors;
  upstream = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
  settings = (pkgs.formats.json { }).generate "vicinae-fleet.json" {
    close_on_focus_loss = true;
    pop_to_root_on_close = true;
    font.normal = {
      family = theme.fonts.sans;
      size = theme.fonts.size;
    };
    theme = {
      dark = {
        name = theme.name;
        icon_theme = theme.icons;
      };
      light = {
        name = theme.name;
        icon_theme = theme.icons;
      };
    };
    launcher_window.opacity = 0.97;
    providers.calculator.preferences.backend = "numen";
  };
  vicinae = pkgs.symlinkJoin {
    name = "vicinae-fleet";
    paths = [ upstream ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/vicinae" --unset LD_LIBRARY_PATH \
        --unset QT_QPA_PLATFORMTHEME --unset QT_STYLE_OVERRIDE \
        --set VICINAE_OVERRIDES ${settings}
    '';
    inherit (upstream) meta;
  };
in
{
  imports = [ inputs.vicinae.nixosModules.default ];
  programs.vicinae.input-server = {
    enable = true;
    package = upstream;
  };
  environment.systemPackages = [ vicinae ];
  systemd.user.targets.mango-session = {
    description = "Mango graphical session";
    bindsTo = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
  };
  systemd.user.services.vicinae = {
    description = "Vicinae desktop launcher";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "mango-session.target" ];
    environment = {
      USE_LAYER_SHELL = "1";
      QT_QPA_PLATFORM = "wayland";
    };
    serviceConfig = {
      ExecStart = "${vicinae}/bin/vicinae server";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
  hjem.users.${identity.username} = {
    xdg.config.files."vicinae/nix.json".source = settings;
    xdg.data.files."vicinae/themes/${theme.name}.toml".source =
      (pkgs.formats.toml { }).generate "vicinae-fleet-theme.toml"
        {
          meta = {
            version = 1;
            name = "Fleet Mocha";
            description = "Catppuccin Mocha with a mauve accent";
            variant = "dark";
            inherits = "vicinae-dark";
          };
          colors = {
            core = {
              background = c.base;
              foreground = c.text;
              secondary_background = c.mantle;
              border = c.surface1;
              accent = c.mauve;
            };
            accents = {
              inherit (c)
                blue
                green
                red
                yellow
                ;
              magenta = c.pink;
              orange = c.peach;
              purple = c.mauve;
              cyan = c.teal;
            };
          };
        };
  };
  nix.settings = {
    extra-substituters = [ "https://vicinae.cachix.org" ];
    extra-trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
  };
}
