{
  flake.modules.nixos.users = { identity, pkgs, ... }: {
    maid.sharedModules = [ ../../lib/maid-audit.nix ];
    users.users.${identity.username} = {
      isNormalUser = true;
      home = "/home/${identity.username}";
      description = identity.fullName;
      shell = pkgs.zsh;
      maid = { };
      extraGroups = [
        "wheel"
        "video"
        "render"
      ];
    };
  };
}
