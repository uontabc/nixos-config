{ pkgs }:
let
  common = with pkgs; [
    git
    pkg-config
    cmake
    ninja
    gnumake
    python312
    uv
    ruff
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];
  runtime = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc
    pkgs.zlib
    pkgs.libffi
    pkgs.openssl
  ];
  cudaToolkit = pkgs.symlinkJoin {
    name = "cuda-development-toolkit";
    paths = with pkgs.cudaPackages; [
      cuda_nvcc
      (pkgs.lib.getDev cuda_cudart)
      (pkgs.lib.getLib cuda_cudart)
      cuda_cccl
    ];
  };
  baseHook = ''
    export UV_PYTHON=${pkgs.python312}/bin/python3
    export UV_PYTHON_DOWNLOADS=never
    export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${runtime}:''${LD_LIBRARY_PATH:-}
  '';
in
{
  default = pkgs.mkShell {
    packages = common ++ [ pkgs.gcc ];
    shellHook = baseHook;
  };

  # On demand: CUDA is deliberately not part of every system rebuild.
  cuda = (pkgs.mkShell.override { stdenv = pkgs.cudaPackages.backendStdenv; }) {
    packages = common ++ [ cudaToolkit ];
    CUDA_PATH = "${cudaToolkit}";
    # nvcc's supported host GCC can differ from the system's default compiler.
    CUDAHOSTCXX = "${pkgs.cudaPackages.backendStdenv.cc}/bin/g++";
    NVCC_PREPEND_FLAGS = "-ccbin ${pkgs.cudaPackages.backendStdenv.cc}/bin/g++";
    shellHook = baseHook + ''
      export LD_LIBRARY_PATH=${pkgs.lib.getLib pkgs.cudaPackages.cuda_cudart}/lib:$LD_LIBRARY_PATH
      export CUDA_HOME=$CUDA_PATH
    '';
  };
}
