{
  graphene = {
    system = "x86_64-linux";
    modules = [ ./graphene ];
  };

  # VPS: future full reinstall. Laptop: verified Linux-only partitions.
  # Uncomment only after disk targets, hardware and machine.nix are ready.
  # nano = {
  #   system = "x86_64-linux"; # or "aarch64-linux"
  #   configRoot = "/etc/nixos"; # location of the repository on the VPS
  #   modules = [ ./nano ];
  # };
  # carbon = {
  #   system = "x86_64-linux";
  #   modules = [ ./carbon ];
  # };
}
