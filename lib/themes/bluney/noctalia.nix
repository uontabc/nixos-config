let
  variants = (builtins.fromJSON (builtins.readFile ./palette.json)).variants;
  ansiNames = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
  ];
  terminalColors =
    colors: offset:
    builtins.listToAttrs (
      builtins.genList (i: {
        name = builtins.elemAt ansiNames i;
        value = builtins.elemAt colors (i + offset);
      }) 8
    );
  convert =
    mode: palette:
    let
      e = palette.editor;
      a = palette.accents;
      t = palette.terminal;
      onAccent = if mode == "light" then "#FFFFFF" else e.bg;
    in
    {
      primary = a.primary;
      on_primary = onAccent;
      secondary = a.secondary;
      on_secondary = onAccent;
      tertiary = a.rose;
      on_tertiary = onAccent;
      error = a.error;
      on_error = onAccent;
      surface = e.bg;
      on_surface = e.fg;
      surface_container = e.surface;
      on_surface_variant = e.comment;
      outline_variant = e.border;
      shadow = if mode == "light" then e.border else e.bg;
      hover = e.surface;
      on_hover = e.fg;
      terminal = {
        inherit (t)
          background
          foreground
          cursor
          cursor_text
          ;
        selection_bg = t.selection_background;
        selection_fg = t.selection_foreground;
        normal = terminalColors palette.ansi 0;
        bright = terminalColors palette.ansi 8;
      };
    };
in
{
  version = 2;
  dark = convert "dark" variants.dark;
  light = convert "light" variants.light;
}
