# Kitty sliding tabs

Adapted from [patricorgi/kitty-sliding-tabs](https://github.com/patricorgi/kitty-sliding-tabs)
at `dd9a95fd49576bc8296c55fb7a7814744a1a3e11`.

- Numbered, stationary labels and a rounded highlight with 180 ms cubic ease-out.
- Replaces the previous slanted tabs, NixOS icon, battery and clock/date display.
- Keeps the shared font, Noctalia/Bluney colors and existing keyboard shortcuts.
- `Ctrl+T`: next tab; `Ctrl+Shift+T`: new tab in the current directory.
- Split separators are 2 px wide; `Ctrl+Alt+H/J/K/L` focuses left/down/up/right.
- `Ctrl+Alt+Arrow` is an alternative; `Ctrl+Alt+Tab` cycles through all splits.
- These operate within one Kitty tab; independent OS windows use Niri's `Super+H/J/K/L`.
- `Ctrl+Shift+O/E`: side-by-side/stacked splits; `Ctrl+Shift+Enter`: stack layout.

For desktop configuration ownership and the keypress overlay, see `../README.md`.

## Linux/DPI/theme adaptation

Upstream assumes a 12 px inset, a particular Retina font aspect ratio and fixed
Catppuccin colors. This version instead sends the actual cell width/height,
current/target bounds and live palette through blank tab-bar cells. The shader
removes those cells from the final frame. Font-size changes, fractional scaling
and Noctalia reloads do not require hard-coded shader RGB or geometry changes.

Keep the bar at the top, horizontal margins at zero, and the inner vertical
margin at zero. Python supplies a one-cell left inset; the outer top margin is
configurable. Inactive tabs use the live terminal background, even when a theme
specifies a different inactive-tab background. The active index is a muted blend
of its foreground/background; inactive indices use ANSI color 8.

When fewer than nine blank cells remain after the tabs, cell metrics cannot be
encoded (width >= 64 px or height >= 128 px), or a highlight bound reaches 8192
px, the bar falls back to ordinary square tabs and instant switching. No metadata
is emitted in these cases. Idle tabs do not run an animation timer. Disabling
`custom_shaders active-tab-slide-lite` also leaves functional, instant tabs.

The shader requires Kitty's full-window offscreen buffer (approximately 63 MiB
per RGBA16 texture at 3840x2160), just like upstream. The integration patches
internal `TabBar` methods and should be rechecked after Kitty upgrades. Tested
with Kitty 0.51.0 on Linux/Wayland at 1.25x scaling.

## Files and activation

`../kitty.nix` installs `tab_bar.py` and both `shaders/active-tab-slide-lite.*`
files through nix-maid. Tests and this README are not installed.

After reviewing the other pending NixOS changes, rebuild and restart Kitty:

```sh
sudo nixos-rebuild switch --flake path:/home/uontabc/nixos-config#NixOS-WorkTable
```

The explicit `path:` also includes new files before they are added to Git. Once
the new files are tracked, the usual Git-backed flake path works as well.

## Checks

From the repository root:

```sh
kitty +launch modules/desktop/kitty/test_tab_bar.py
# In a running niri session; sends real Wayland keys to a disposable Kitty only.
kitty +launch modules/desktop/kitty/test_keybindings.py --wtype /path/to/wtype
nixfmt --check modules/desktop/kitty.nix
nix eval --offline --raw \
  'path:/home/uontabc/nixos-config#nixosConfigurations.NixOS-WorkTable.config.system.build.toplevel.drvPath'
```

Tests cover framebuffer encoding, easing, rapid retargeting, layout changes,
live colors, idle timers, safe fallbacks and headless Slang pipeline compilation.
Visual smoke testing uses an isolated `KITTY_CONFIG_DIRECTORY`, not the active
nix-maid configuration or a system activation.
