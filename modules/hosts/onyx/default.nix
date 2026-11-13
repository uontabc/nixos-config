{ self, ... }:
{
  hosts.onyx = {
    system = "x86_64-linux";
    module = { pkgs, ... }: {
      imports = with self.modules.nixos; [
        wsl
        development
        docker
        yazi
      ];
      # Keep Zellij opt-in: no managed config or automatic shell startup.
      environment.systemPackages = [ pkgs.zellij ];
      system.stateVersion = "26.05";
    };
  };
}
