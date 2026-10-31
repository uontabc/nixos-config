{ ... }:
{
  imports = [
    ./machine.nix
    ../../modules/profiles/development.nix
  ];

  networking.hostName = "server";
  # Add this machine's native GPU driver here if needed.
}
