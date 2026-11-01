{ pkgs, ... }:
{
  # Baseline support for editing this configuration; project LSPs live in shells.
  environment.systemPackages = with pkgs; [
    nil
    lua-language-server
    stylua
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
