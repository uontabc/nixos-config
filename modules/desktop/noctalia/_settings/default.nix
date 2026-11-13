{ identity }:
let
  theme = import ../../../../lib/theme.nix;
in
# These fragments own disjoint top-level sections of Noctalia's config.
(import ./bar.nix)
// (import ./appearance.nix { inherit identity; })
// (import ./session.nix { inherit theme; })
