# nix-maid's file options only create links. For application-writable configs,
# link to a private copy seeded by tmpfiles, never directly to the Nix store.
{ pkgs }:
{
  path,
  text,
  writable ? false,
}:
let
  source = pkgs.writeText ("maid-" + builtins.replaceStrings [ "/" ] [ "-" ] path) text;
  # A changed Nix source gets fresh defaults; unchanged sources keep app edits.
  mutablePath = "{{xdg_state_home}}/nix-maid/writable/${builtins.baseNameOf source}/${path}";
in
{
  file.xdg_config.${path}.source = if writable then mutablePath else source;
  # Override the store file's root ownership when copying as a normal user.
  systemd.tmpfiles.dynamicRules =
    if writable then [ "C ${mutablePath} 0600 {{user}} {{group}} - ${source}" ] else [ ];
}
