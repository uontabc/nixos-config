{
  flake.modules.nixos.git = { identity, ... }: {
    users.users.${identity.username}.maid.file.xdg_config."git/config".text = ''
      [user]
        name = ${identity.fullName}
        email = ${identity.email}
      [init]
        defaultBranch = main
      [pull]
        ff = only
      [push]
        autoSetupRemote = true
      [fetch]
        prune = true
      [core]
        editor = nvim
      [diff]
        algorithm = histogram
      [merge]
        conflictStyle = zdiff3
    '';
  };
}
