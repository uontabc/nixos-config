#!/usr/bin/env bash
# Exercise generated tmpfiles rules in disposable homes, without switching NixOS
# or contacting the live user service manager. Requires nix, jq and systemd.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
hosts=("$@")
if ((${#hosts[@]} == 0)); then
  hosts=(NixOS-WorkTable onyx)
fi

for host in "${hosts[@]}"; do
  maid=".#nixosConfigurations.$host.config.users.users.uontabc.maid"
  nix build --no-link "$maid.build.bundle"
  nix eval --json "$maid" --apply 'c: {
    renderer = c.build.tmpfileRenderer.outPath;
    files = c.file;
  }' > "$work/$host.json"

  (
    export HOME="$work/$host/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_RUNTIME_DIR="$work/$host/runtime"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/btop" "$XDG_CONFIG_HOME/kitty"
    mkdir -m 0700 "$XDG_RUNTIME_DIR"

    # Simulate old manager-owned links and regular writable configurations.
    ln -s /dev/null "$HOME/.zshrc"
    printf 'old btop config\n' > "$XDG_CONFIG_HOME/btop/btop.conf"
    printf 'old kitty config\n' > "$XDG_CONFIG_HOME/kitty/kitty.conf"

    renderer=$(jq -r .renderer "$work/$host.json")
    rules="$work/$host/tmpfiles.conf"
    "$renderer/bin/nix-maid-tmpfile-renderer" > "$rules"
    apply_rules() {
      # Explicit filename: never run unrelated system/user tmpfiles rules.
      systemd-tmpfiles --user --create --remove "$rules"
    }
    apply_rules

    count=0
    while IFS=$'\t' read -r root target; do
      case "$root" in
        home) base="$HOME" ;;
        xdg_config) base="$XDG_CONFIG_HOME" ;;
        xdg_data) base="$XDG_DATA_HOME" ;;
        xdg_state) base="$XDG_STATE_HOME" ;;
        xdg_cache) base="$XDG_CACHE_HOME" ;;
        xdg_runtime) base="$XDG_RUNTIME_DIR" ;;
        *) echo "Unknown file root: $root" >&2; exit 1 ;;
      esac
      test -L "$base/$target"
      test -e "$base/$target"
      count=$((count + 1))
    done < <(jq -r '.files | to_entries[] as $root |
      $root.value[] | [$root.key, .target] | @tsv' "$work/$host.json")

    writable=("$XDG_CONFIG_HOME/btop/btop.conf")
    if [[ "$(readlink -f "$XDG_CONFIG_HOME/kitty/kitty.conf")" == "$XDG_STATE_HOME/"* ]]; then
      writable+=("$XDG_CONFIG_HOME/kitty/kitty.conf")
    fi
    for file in "${writable[@]}"; do
      [[ "$(readlink -f "$file")" == "$XDG_STATE_HOME/nix-maid/writable/"* ]]
      test "$(stat -Lc '%a' "$file")" = 600
      printf '\n# application edit survives activation\n' >> "$file"
    done
    apply_rules
    for file in "${writable[@]}"; do
      grep -q 'application edit survives activation' "$file"
    done

    # Application state must remain writable next to the managed leaf files.
    touch "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"
    if [[ -d "$XDG_CONFIG_HOME/noctalia" ]]; then
      touch "$XDG_CONFIG_HOME/noctalia/gui-owned-state"
    fi
    printf 'PASS %s: %s managed files, writable configs survive reactivation\n' "$host" "$count"
  )
done
