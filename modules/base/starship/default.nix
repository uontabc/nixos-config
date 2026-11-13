{
  flake.modules.nixos.starship =
    { identity, pkgs, ... }:
    let
      theme = import ../../../lib/theme.nix;
      c = theme.colors;
      settings = (builtins.fromTOML (builtins.readFile ./starship.toml)) // {
        palette = "theme";
        palettes.theme = c // {
          cyan = c.${theme.accent};
          purple = c.mauve;
        };
      };
    in
    {
      hjem.users.${identity.username}.xdg.config.files."starship.toml".source =
        (pkgs.formats.toml { }).generate "starship.toml"
          settings;
    };
}
