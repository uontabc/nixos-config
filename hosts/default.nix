{
  wsl = {
    system = "x86_64-linux";
    modules = [ ./wsl ];
  };

  # Register vps and server after their architecture and hardware are known.
  # Each host chooses its own modules; WSL settings are not shared.
}
