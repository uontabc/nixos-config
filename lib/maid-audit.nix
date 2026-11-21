# Verify deployed links against the actual nix-maid declarations, not a hand-kept list.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  manifest = (pkgs.formats.json { }).generate "nix-maid-managed-files.json" (
    lib.concatLists (
      lib.mapAttrsToList (
        category: files:
        map (file: {
          inherit category;
          inherit (file) target;
        }) (lib.attrValues files)
      ) config.file
    )
  );
  checker = pkgs.writeScriptBin "maid-check" ''
    #!${lib.getExe pkgs.python312}
    import json
    import os
    from pathlib import Path
    import sys

    home = Path.home()
    roots = {
        "home": home,
        "xdg_config": Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")),
        "xdg_data": Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")),
        "xdg_state": Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")),
        "xdg_cache": Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")),
        "xdg_runtime": Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")),
    }
    failures = 0
    with open("${manifest}") as source:
        entries = json.load(source)
    for entry in entries:
        category, target = entry["category"], entry["target"]
        path = roots[category] / target
        suffix = "" if category == "home" else "-" + category.replace("_", "-")
        expected = roots["xdg_state"] / "nix-maid" / ("static" + suffix) / target
        if not path.is_symlink():
            print(f"FAIL not a nix-maid link: {path}")
        elif Path(os.path.abspath(path.parent / os.readlink(path))) != expected:
            print(f"FAIL unexpected link target: {path} -> {os.readlink(path)}")
        elif not path.exists():
            print(f"FAIL broken link: {path}")
        else:
            print(f"OK {path}")
            continue
        failures += 1
    print(f"{len(entries) - failures}/{len(entries)} nix-maid files verified")
    sys.exit(bool(failures))
  '';
in
{
  _class = "maid";
  packages = [ checker ];
  file.xdg_config."nix-maid/managed-files.json".source = manifest;
}
