{ ... }:
{
  # During installation, generate the target's hardware configuration with
  # nixos-generate-config --root /mnt, copy hardware-configuration.nix here,
  # and import it after reviewing the actual root, EFI and encryption settings.
  # imports = [ ./hardware-configuration.nix ];

  assertions = [
    {
      assertion = false;
      message = "Laptop template: replace hosts/laptop/machine.nix with the generated hardware configuration and actual root/EFI/encryption mounts before installation.";
    }
  ];
}
