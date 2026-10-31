{
  wsl = {
    system = "x86_64-linux";
    modules = [ ./wsl ];
  };

  # Templates: import each machine's existing configuration in machine.nix,
  # choose its actual architecture, then uncomment the corresponding entry.
  # vps = {
  #   system = "x86_64-linux"; # or "aarch64-linux"
  #   configRoot = "/etc/nixos"; # location of the repository on the VPS
  #   modules = [ ./vps ];
  # };
  # laptop = {
  #   system = "x86_64-linux";
  #   modules = [ ./laptop ];
  # };
}
