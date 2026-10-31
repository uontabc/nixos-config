#!/bin/sh
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export HTTP_PROXY=$http_proxy HTTPS_PROXY=$https_proxy
export no_proxy=localhost,127.0.0.1,::1
export NO_PROXY=$no_proxy
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/run/current-system/sw/share/nix-ld/lib
export PATH=/run/current-system/sw/bin:$PATH
export NIX_CONFIG='experimental-features = nix-command flakes'
cd /home/uontabc/nixos-config || exit 1
exec /opt/mcp-nixos/venv/bin/mcp-nixos
