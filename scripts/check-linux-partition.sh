#!/usr/bin/env bash
set -euo pipefail
device=${1:?partition required}
label=${2:?expected partition label required}
filesystem=${3:?expected filesystem required}
[[ -b "$device" ]] || { echo "Not a block device: $device" >&2; exit 1; }
[[ $(lsblk -ndo TYPE "$device") == part ]] || { echo 'Refusing to format a whole disk.' >&2; exit 1; }
[[ $(lsblk -ndo PARTLABEL "$device") == "$label" ]] || { echo "Partition label must be $label." >&2; exit 1; }
current=$(blkid -o value -s TYPE "$device" || true)
[[ -z "$current" || "$current" == "$filesystem" ]] || {
  echo "Refusing unexpected existing filesystem: $current" >&2
  exit 1
}
if [[ "$label" == NIXOS_BOOT ]]; then
  [[ $(lsblk -ndo PARTTYPE "$device") == bc13c2ff-59e6-4262-a352-b275fd6f7172 ]] || {
    echo 'NIXOS_BOOT must have the XBOOTLDR GPT type (EA00).' >&2
    exit 1
  }
fi
