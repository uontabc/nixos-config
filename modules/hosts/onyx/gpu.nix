{ ... }:
{
  flake.modules.nixos.wsl-gpu =
    { lib, pkgs, ... }:
    {
      # NixOS-WSL imports the Windows NVIDIA driver into /run/opengl-driver/lib.
      # Do not install a second NVIDIA kernel driver inside WSL.
      hardware.graphics.enable = true;

      # Project runtimes belong in devShells. Only expose the host GPU globally.
      environment.sessionVariables.LD_LIBRARY_PATH = "/run/opengl-driver/lib";

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "nvidia-smi" ''
          export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}
          exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /usr/lib/wsl/lib/nvidia-smi "$@"
        '')
      ];
    };
}
