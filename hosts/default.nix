{
  wsl = {
    system = "x86_64-linux";
    modules = [ ./wsl ];
  };

  # VPS: retain its existing configuration. Laptop: use installer-generated
  # hardware and mounts. Uncomment each entry only after machine.nix is ready.
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
