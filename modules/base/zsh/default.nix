{
  flake.modules.nixos.shell = { identity, pkgs, ... }: {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      promptInit = "";
    };
    # Manage the individual file so shell history remains writable.
    hjem.users.${identity.username}.files.".zshrc".source = pkgs.replaceVars ./interactive.zsh {
      history_guard = "${pkgs.python312}/bin/python3 ${./history-guard.py}";
      history_zsh = "${pkgs.zsh}/bin/zsh";
    };
  };
}
