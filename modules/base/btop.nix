{
  flake.modules.nixos.btop =
    { identity, pkgs, ... }:
    {
      hjem.users.${identity.username}.xdg.config.files."btop/btop.conf" = {
        # btop saves its layout on exit; keep the generated defaults writable.
        type = "copy";
        clobber = true;
        permissions = "0600";
        text = ''
          color_theme = "${pkgs.btop}/share/btop/themes/tokyo-night.theme"
          theme_background = true
          truecolor = true
        '';
      };
    };
}
