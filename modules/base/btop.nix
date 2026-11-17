{
  flake.modules.nixos.btop =
    {
      config,
      identity,
      lib,
      pkgs,
      ...
    }:
    let
      configFile = import ../../lib/maid-config-file.nix { inherit pkgs; };
      templates =
        config.users.users.${identity.username}.maid.programs.noctalia.settings.theme.templates or { };
      useNoctaliaTheme =
        (templates.enable_builtin_templates or false) && lib.elem "btop" (templates.builtin_ids or [ ]);
      colorTheme = if useNoctaliaTheme then "noctalia" else "bluney-light";
    in
    {
      users.users.${identity.username}.maid = lib.mkMerge [
        {
          file.xdg_config."btop/themes/bluney-light.theme".source =
            ../../lib/themes/bluney/bluney-light.theme;
        }
        (configFile {
          path = "btop/btop.conf";
          # btop saves its layout on exit; keep the generated defaults writable.
          writable = true;
          text = ''
            color_theme = "${colorTheme}"
            theme_background = true
            truecolor = true
          '';
        })
      ];
    };
}
