function zsh_add_file() {
    [ -f "$1" ] && source "$1"
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

function zsh_update_completion() {
    if [[ -a /var/cache/zsh/pacman ]]; then
        local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
        if (( zshcache_time < paccache_time )); then
            rehash
            compinit
            zshcache_time="$paccache_time"
        fi
    fi
}

function zsh_add_completion() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    if [ -d "$ZSHDIR/plugins/$PLUGIN_NAME" ]; then
        # For completions
        completion_file_path=$(ls $ZSHDIR/plugins/$PLUGIN_NAME/_*)
        fpath+="$(dirname "${completion_file_path}")"
        zsh_add_file "$ZSHDIR/plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh"
    else
        git clone "https://github.com/$1.git" "$ZSHDIR/plugins/$PLUGIN_NAME"
        fpath+=$(ls $ZSHDIR/plugins/$PLUGIN_NAME/_*)
        [ -f $ZSHDIR/.zccompdump ] && $ZSHDIR/.zccompdump
    fi
    completion_file="$(basename "${completion_file_path}")"
    if [ "$2" = true ] && compinit "${completion_file:1}"
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
