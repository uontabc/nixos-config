{
  flake.modules.nixos.users = { identity, pkgs, ... }: {
    users.users.${identity.username} = {
      isNormalUser = true;
      home = "/home/${identity.username}";
      description = identity.fullName;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "video"
        "render"
      ];
    };
    hjem.users.${identity.username}.enable = true;
  };
}
