alias sourcezsh='source ~/.zshrc'
alias cat='bat --style=plain --paging=never'
alias ccat='\cat'               # original cat command

# Tools
alias v='nvim'
alias ff='fastfetch'
alias lg='lazygit'
alias y='yazi'
alias oc='opencode'
alias wf='wifi-tui'

# Coloring
alias l='ls -lah --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'

# Chezmoi
alias chd='chezmoi cd'
alias chra='chezmoi re-add'
alias cha='chezmoi add'
alias chap='chezmoi apply'

# Tmux
alias ta='tmux attach'
alias t='tmux'
alias tk='tmux kill-server'
alias tl='tmux ls'
