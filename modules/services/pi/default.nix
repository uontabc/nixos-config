{ self, ... }:
{
  flake.modules.nixos.pi =
    { inputs, ... }:
    {
      imports = [
        inputs.pi.nixosModules.default
        self.modules.nixos.pi-theme
        self.modules.nixos.pi-extensions
        self.modules.nixos.pi-lsp
        self.modules.nixos.pi-mcp
        self.modules.nixos.pi-open-tui
        self.modules.nixos.pi-web-search
      ];
      programs.pi.coding-agent.enable = true;
      nix.settings = {
        extra-substituters = [
          "https://pi.cachix.org"
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
