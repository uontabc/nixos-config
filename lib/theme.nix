let
  # Upstream palette.json is the source of truth; README colors can lag behind it.
  palette = (builtins.fromJSON (builtins.readFile ./themes/bluney/palette.json)).variants.light;
  e = palette.editor;
  a = palette.accents;
in
{
  name = "bluney-light";
  style = "light";
  accent = "blue";
  ansi = palette.ansi;
  fonts = {
    sans = "Rec Mono Linear";
    mono = "Rec Mono Linear";
    symbols = "Symbols Nerd Font Mono";
    # Use Simplified Chinese Source Han Sans for UI and terminal CJK glyphs.
    cjk = "Source Han Sans SC";
    cjkMono = "Source Han Sans SC";
    size = 11;
  };
  gtkName = "Bluney-Light";
  fcitxName = "deepinExp-light";
  cursorName = "Bibata-Modern-Ice";
  cursorSize = 24;
  icons = "Tela";
  # Keep shared role names stable for the terminal, prompt, Yazi and Pi.
  colors = {
    rosewater = e.fg;
    flamingo = a.error;
    pink = a.rose;
    mauve = a.rose;
    red = a.error;
    maroon = a.error;
    peach = a.yellow;
    yellow = a.yellow;
    green = a.primary;
    teal = a.cyan;
    sky = a.cyan;
    sapphire = a.secondary;
    blue = a.primary;
    lavender = a.rose;
    text = e.fg;
    subtext1 = e.comment;
    subtext0 = e.comment;
    overlay2 = e.comment;
    overlay1 = e.comment;
    overlay0 = e.border;
    surface2 = e.border;
    surface1 = e.surface;
    surface0 = e.surface;
    selection = palette.terminal.selection_background;
    base = e.bg;
    mantle = e.surface;
    crust = e.surface;
  };
}
