{ lib, pkgs, ... }:
{
  # NixOS-WSL imports the Windows NVIDIA driver into /run/opengl-driver/lib.
  # Do not install a second NVIDIA kernel driver inside WSL.
  hardware.graphics.enable = true;

  environment.sessionVariables.LD_LIBRARY_PATH = lib.concatStringsSep ":" [
    "/usr/lib/wsl/lib"
    "/run/opengl-driver/lib"
    "/run/current-system/sw/share/nix-ld/lib"
  ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nvidia-smi" ''
      export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}
      exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /usr/lib/wsl/lib/nvidia-smi "$@"
    '')
    (pkgs.writeShellScriptBin "cuda-check" ''
      export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}
      exec ${pkgs.python312}/bin/python ${../../scripts/cuda-check.py}
    '')
  ];
}
