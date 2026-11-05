{ self, ... }:
{
  flake.modules.nixos.proxy-node =
    { pkgs, ... }:
    {
      imports = [ self.modules.nixos.sing-box-reality ];
      environment.systemPackages = with pkgs; [
        curl
        jq
        tmux
        btop
      ];
      # Existing SSH access and account policy are imported by hosts/umbra/machine.nix.
    };
}
