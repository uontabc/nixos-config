{ pkgs, ... }:
{
  imports = [ ../services/sing-box-reality.nix ];
  environment.systemPackages = with pkgs; [
    curl
    jq
    tmux
    btop
  ];
  # Existing SSH access and account policy are imported by hosts/vps/machine.nix.
}
