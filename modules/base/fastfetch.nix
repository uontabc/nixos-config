{
  flake.modules.nixos.fastfetch =
    { identity, pkgs, ... }:
    let
      theme = import ../../lib/theme.nix;
      c = theme.colors;
    in
    {
      hjem.users.${identity.username}.xdg.config.files."fastfetch/config.jsonc".source =
        (pkgs.formats.json { }).generate "fastfetch-config.jsonc"
          {
            "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
            logo = {
              type = "builtin";
              source = "NixOS_small";
              padding.right = 3;
              color = {
                "1" = c.${theme.accent};
                "2" = c.sky;
              };
            };
            display = {
              separator = "  ";
              key.width = 10;
              color = {
                keys = c.${theme.accent};
                title = c.${theme.accent};
              };
            };
            modules = [
              "title"
              {
                type = "os";
                key = "OS";
                format = "{name}";
              }
              "kernel"
              {
                type = "wm";
                key = "WM";
              }
              {
                type = "cpu";
                key = "CPU";
                format = "{name}";
              }
              {
                type = "gpu";
                key = "GPU";
                format = "{name}";
              }
              {
                type = "memory";
                format = "{used} / {total}";
              }
              "uptime"
            ];
          };
    };
}
