#!/usr/bin/env bash
set -euo pipefail
device=${1:?Btrfs Linux root partition required}
account=${2:?account name required}
[[ "$account" =~ ^[a-z_][a-z0-9_-]*$ ]] || exit 1
[[ -b "$device" ]] || { echo 'Root reset requires a block device.' >&2; exit 1; }
if findmnt -rn --source "$device" >/dev/null; then
  echo 'Refusing root reset: the filesystem is already mounted.' >&2
  exit 1
fi
directory=$(mktemp -d /run/nixos-root-reset.XXXXXX)
mounted=false
cleanup() {
  if $mounted; then umount "$directory"; fi
  rmdir "$directory"
}
trap cleanup EXIT
mount -t btrfs -o subvolid=5 "$device" "$directory"
mounted=true

# Refuse an unrelated Btrfs filesystem or an incomplete installation before
# deleting anything. Sibling subvolumes are never removed or archived.
for name in @home @nix @persist; do
  [[ ! -L "$directory/$name" ]]
  btrfs subvolume show "$directory/$name" >/dev/null
done
test -s "$directory/@persist/secrets/$account-password" || {
  echo "Seed /persist/secrets/$account-password before enabling root reset." >&2
  exit 1
}
root="$directory/@root"
[[ ! -L "$root" ]]
if [[ -e "$root" ]]; then
  btrfs subvolume show "$root" >/dev/null
  btrfs subvolume delete --recursive "$root"
fi
btrfs subvolume create "$root"
