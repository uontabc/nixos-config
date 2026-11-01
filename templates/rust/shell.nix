{ pkgs }:
pkgs.mkShell {
  name = "rust-project";
  packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    pkg-config
  ];
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
