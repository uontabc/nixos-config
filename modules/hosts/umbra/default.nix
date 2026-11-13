{ self, ... }:
{
  hosts.umbra = {
    # Enable only after disk, firmware, hardware, networking and SSH are ready.
    enable = false;
    system = "x86_64-linux"; # or "aarch64-linux"
    configRoot = "/etc/nixos";
    module = { inputs, ... }: {
      imports = [
        inputs.disko.nixosModules.disko
        self.modules.nixos.proxy-node
      ];
    };
  };
}
