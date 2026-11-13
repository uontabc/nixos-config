{ self, ... }:
{
  # Discovery registers features; only these explicit compositions enable them.
  flake.modules.nixos = {
    base = {
      imports = with self.modules.nixos; [
        nix
        management
      ];
    };

    development = {
      imports = with self.modules.nixos; [
        editor
        pi
        users
        shell
        git
        neovim
        kitty
        starship
        fastfetch
        btop
        development-tools
      ];
    };

    desktop = {
      imports = with self.modules.nixos; [
        niri
        noctalia
        input-method
        apps
        gaming
        fonts
        gtk-qt
      ];
    };

    proxy-node = { pkgs, ... }: {
      imports = [ self.modules.nixos.sing-box-reality ];
      environment.systemPackages = with pkgs; [
        curl
        jq
        tmux
        btop
      ];
      # SSH access and account policy belong to modules/hosts/NixOS-WorkCloud/machine.nix.
    };
  };
}
