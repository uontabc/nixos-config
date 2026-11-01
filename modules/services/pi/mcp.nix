{
  configRoot,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.mcp-nixos ];
  programs.pi.coding-agent.mcp.mcpServers.nixos = {
    command = lib.getExe pkgs.mcp-nixos;
    cwd = configRoot;
    exposure = "direct";
    description = "Look up current NixOS packages, options, flakes and documentation before changing Nix configuration.";
  };
}
