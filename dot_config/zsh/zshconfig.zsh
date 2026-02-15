COMPLETION_WAITING_DOTS="true"

# ===== Color Configuration =====

if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

export LESS='-R'

autoload -Uz compinit
compinit

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
