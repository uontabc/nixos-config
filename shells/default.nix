{ pkgs }:
{
  # Tools for maintaining this repository and installing remote hosts.
  default = pkgs.mkShellNoCC {
    name = "nixos-config";
    packages = [
      pkgs.nixfmt
      pkgs.nil
      pkgs.nixos-anywhere
    ];
  };
  python = import ../templates/python/shell.nix { inherit pkgs; };
  rust = import ../templates/rust/shell.nix { inherit pkgs; };
  cpp = import ../templates/cpp/shell.nix { inherit pkgs; };
}
