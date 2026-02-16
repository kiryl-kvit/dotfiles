function zsh_add_file() {
    [ -f "$1" ] && source "$1"
}

function zsh_append_path() {
    [ -f "$1" ] && export "$1:$PATH"
}

function zsh_add_plugin() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    FALLBACK_NAME=$(echo $PLUGIN_NAME | cut -d "-" -f 2)
    DIR_NAME="$ZSHDIR/plugins/$PLUGIN_NAME"
    if [ -d "$DIR_NAME" ]; then
        # For plugins
        zsh_add_file "$DIR_NAME/$PLUGIN_NAME.plugin.zsh" || \
            zsh_add_file "$DIR_NAME/$PLUGIN_NAME.zsh" || \
            zsh_add_file "$DIR_NAME/$FALLBACK_NAME.plugin.zsh"
    else
        git clone "https://github.com/$1.git" "$ZSHDIR/plugins/$PLUGIN_NAME"
    fi
}

function pf() {
  pacman -Slq | fzf --multi --preview-window '55%,wrap' --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk "{print \$2}")' | xargs -ro sudo pacman -S
}

function ppf() {
  yay -Slq | fzf --multi --preview-window '55%,wrap' --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk "{print \$2}")' | xargs -ro yay -S
}

function pd() {
  pacman -Qq | fzf --multi --preview-window '55%,wrap' --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns
}

function sudo-last-command() {
  if [[ -z $BUFFER ]]; then
    BUFFER="sudo $(fc -ln -1)"
  elif [[ $BUFFER == sudo\ * ]]; then
    BUFFER=${BUFFER#sudo }
  else
    BUFFER="sudo $BUFFER"
  fi
  CURSOR=${#BUFFER}
}

if [[ -o interactive ]]; then
  zle -N sudo-last-command
fi
