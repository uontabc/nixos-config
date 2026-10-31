{ ... }:
{
  # During installation, generate the target's hardware configuration with
  # nixos-generate-config --root /mnt, copy hardware-configuration.nix here,
  # and import it after reviewing the actual unencrypted root and EFI mounts.
  # imports = [ ./hardware-configuration.nix ];

  assertions = [
    {
      assertion = false;
      message = "Laptop template: Windows shares the disk, no Linux space is allocated yet; supply the generated hardware configuration and actual unencrypted root/EFI mounts before installation.";
    }
  ];
}
