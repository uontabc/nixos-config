#!/usr/bin/env bash
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
  echo 'Run with sudo.' >&2
  exit 1
fi
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890
python_path=$(readlink -f "$(command -v python3.12)")
mkdir -p /opt/mcp-nixos/bin
if [ ! -f /opt/mcp-nixos/venv/pyvenv.cfg ]; then
  uv venv --python "$python_path" /opt/mcp-nixos/venv
fi
uv pip install --python /opt/mcp-nixos/venv/bin/python -r "$source_dir/mcp/requirements-lock.txt"
ln -sfn "$python_path" /opt/mcp-nixos/venv/bin/python
sed -i "s|^home = .*|home = $(dirname "$python_path")|" /opt/mcp-nixos/venv/pyvenv.cfg
nix-store --add-root /opt/mcp-nixos/python-root --indirect --realise "${python_path%/bin/*}"
install -m 755 "$source_dir/scripts/mcp-nixos-launcher.sh" /opt/mcp-nixos/bin/mcp-nixos
