# History lives outside the declarative configuration.
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=50000
# SHARE_HISTORY already appends each command; do not combine it with the
# mutually exclusive INC_APPEND_HISTORY / INC_APPEND_HISTORY_TIME options.
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
setopt HIST_FCNTL_LOCK HIST_SAVE_BY_COPY EXTENDED_HISTORY
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME

# Validate before Zsh imports the file. If recovery fails, keep the original
# untouched and use memory-only history for this session.
if ! @history_guard@ "$HISTFILE" @history_zsh@; then
  print -u2 'zsh: disk history disabled for this session; original history is unchanged.'
  unset HISTFILE
  SAVEHIST=0
fi
setopt AUTO_CD INTERACTIVE_COMMENTS
bindkey -e

alias ls='eza --group-directories-first'
alias ll='eza -lh --group-directories-first --git'
alias la='eza -lah --group-directories-first --git'
alias cat='bat --paging=never'
alias v='nvim'
alias lg='lazygit'
alias ..='cd ..'
# Enter the current project's default shell.
alias dev='nix develop -c zsh'

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
# direnv's hook is supplied by the NixOS programs.direnv module.
