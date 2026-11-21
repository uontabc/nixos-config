{
  flake.modules.nixos."NixOS-WorkTable" = {
    # Keep the legacy proxy disabled; removing its replacement must not restart it.
    systemd.services.honk-core.enable = false;
  };
}
