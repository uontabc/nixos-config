# History lives outside the declarative configuration.
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS
bindkey -e

alias ls='eza --group-directories-first'
alias ll='eza -lh --group-directories-first --git'
alias la='eza -lah --group-directories-first --git'
alias cat='bat --paging=never'
alias v='nvim'
alias lg='lazygit'
alias ..='cd ..'
alias dev='nix develop /etc/nixos#default -c zsh'
alias cuda-dev='nix develop /etc/nixos#cuda -c zsh'

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
# direnv's hook is supplied by the NixOS programs.direnv module.
