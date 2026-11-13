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
      templates =
        config.hjem.users.${identity.username}.programs.noctalia.settings.theme.templates or { };
      useNoctaliaTheme =
        (templates.enable_builtin_templates or false) && lib.elem "btop" (templates.builtin_ids or [ ]);
      colorTheme =
        if useNoctaliaTheme then "noctalia" else "${pkgs.btop}/share/btop/themes/tokyo-night.theme";
    in
    {
      hjem.users.${identity.username}.xdg.config.files."btop/btop.conf" = {
        # btop saves its layout on exit; keep the generated defaults writable.
        type = "copy";
        clobber = true;
        permissions = "0600";
        text = ''
          color_theme = "${colorTheme}"
          theme_background = true
          truecolor = true
        '';
      };
    };
}
