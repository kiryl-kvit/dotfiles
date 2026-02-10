#!/bin/bash

declare -A plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

install_oh_my_zsh() {
  PLUGIN_DIR="$ZSH_CUSTOM/plugins"
  mkdir -p "$PLUGIN_DIR"

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  for name in "${!plugins[@]}"; do
    dest="$PLUGIN_DIR/$name"
    repo="${plugins[$name]}"
    git clone --depth=1 "$repo" "$dest"
  done
}

install_starship() {
  curl -sS https://starship.rs/install.sh | sh
}

install_yay() {
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  git clone https://aur.archlinux.org/yay.git "$TMPDIR/yay"
  cd "$TMPDIR/yay"
  makepkg -si --noconfirm
  cd -
}

install_arch() {
  install_yay
  sudo pacman -S zoxide fzf fd ripgrep git-delta fastfetch neovim ttf-firacode-nerd
}

install_neovim() {
  NVIM_REPO="https://github.com/kiryl-kvit/nvim.git"
  NVIM_DIR="$HOME/.config/nvim"
  if [ ! -d "$NVIM_DIR" ]; then
    git clone "$NVIM_REPO" "$NVIM_DIR"
  fi
}

install_debian() {
  sudo apt update
  sudo apt install -y fzf fd-find ripgrep curl

  if [ ! -e /usr/local/bin/fd ]; then
    sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
  fi

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) DEB_ARCH="amd64" ;;
    aarch64|arm64) DEB_ARCH="arm64" ;;
  esac

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  sudo mv ~/.local/bin/zoxide /usr/local/bin/ 2>/dev/null || true

  DELTA_VERSION="$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
  curl -sL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${DEB_ARCH}.deb" -o "$TMPDIR/delta.deb"
  sudo dpkg -i "$TMPDIR/delta.deb"

  FASTFETCH_VERSION="$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
  curl -sL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-${DEB_ARCH}.deb" -o "$TMPDIR/fastfetch.deb"
  sudo dpkg -i "$TMPDIR/fastfetch.deb"

  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt update
  sudo apt install -y neovim

  TMP_ZIP="$(mktemp --suffix=.zip)"
  FONT_DIR="/usr/local/share/fonts/nerd-fonts"

  sudo mkdir -p "$FONT_DIR"
  curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -o "$TMP_ZIP"
  sudo unzip -o "$TMP_ZIP" -d "$FONT_DIR"
  rm -f "$TMP_ZIP"
  sudo fc-cache -fv
  fc-cache -fv
}

install_oh_my_zsh
install_starship

if command -v apt >/dev/null 2>&1; then
  install_debian
elif command -v pacman >/dev/null 2>&1; then
  install_arch
fi

install_neovim
