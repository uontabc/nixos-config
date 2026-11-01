{ pkgs }:
pkgs.mkShellNoCC {
  name = "python-project";
  packages = with pkgs; [
    python312
    uv
    ruff
    pyright
  ];

  UV_PYTHON = "${pkgs.python312}/bin/python3";
  UV_PYTHON_DOWNLOADS = "never";
  PYTHONNOUSERSITE = "1";

  # Runtime libraries for binary wheels are scoped to this project shell.
  shellHook = ''
    export LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc
        pkgs.zlib
        pkgs.libffi
        pkgs.openssl
      ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
  '';
}
