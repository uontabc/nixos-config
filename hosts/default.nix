{
  onyx = {
    system = "x86_64-linux";
    modules = [ ./onyx ];
  };

  # VPS: future full reinstall. Laptop: verified Linux-only partitions.
  # Uncomment only after disk targets, hardware and machine.nix are ready.
  # umbra = {
  #   system = "x86_64-linux"; # or "aarch64-linux"
  #   configRoot = "/etc/nixos"; # location of the repository on the VPS
  #   modules = [ ./umbra ];
  # };
  # obsidian = {
  #   system = "x86_64-linux";
  #   modules = [ ./obsidian ];
  # };
}
