{ pkgs, ... }:
{
  # rust-analyzer needs standard-library sources for navigation and completion.
  environment.sessionVariables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

  environment.systemPackages = with pkgs; [
    # Python: keep dependencies inside projects with `uv venv` / `uv sync`.
    python312
    uv
    ruff
    pyright

    # Rust: the toolchain and editor share the same nixpkgs snapshot.
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # C / C++ and native Python extensions.
    gcc
    gdb
    cmake
    ninja
    gnumake
    pkg-config
    ccache
    clang-tools
    lldb

    # LazyVim builds parsers locally; language servers come from Nix.
    nodejs
    tree-sitter
    lua-language-server
    stylua
    nil
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      openssl
      curl
      libffi
      libGL
      libGLU
      glib
      libgcc
    ];
  };
}
