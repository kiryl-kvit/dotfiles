#!/usr/bin/env bash

declare -A plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed, skipping..."
    return
  fi

  PLUGIN_DIR="$ZSH_CUSTOM/plugins"
  mkdir -p "$PLUGIN_DIR"

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  for name in "${!plugins[@]}"; do
    dest="$PLUGIN_DIR/$name"
    repo="${plugins[$name]}"
    if [ -d "$dest" ]; then
      echo "Plugin $name already installed, skipping..."
    else
      git clone --depth=1 "$repo" "$dest"
    fi
  done
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    echo "Starship already installed, skipping..."
    return
  fi
  curl -sS https://starship.rs/install.sh | sh
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    echo "yay already installed, skipping..."
    return
  fi
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  git clone https://aur.archlinux.org/yay.git "$TMPDIR/yay"
  cd "$TMPDIR/yay"
  makepkg -si --noconfirm
  cd -
}

install_arch() {
  install_yay
  
  local packages=(zoxide fzf fd ripgrep git-delta fastfetch neovim ttf-firacode-nerd)
  local to_install=()
  
  for pkg in "${packages[@]}"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done
  
  if [ ${#to_install[@]} -eq 0 ]; then
    echo "All Arch packages already installed, skipping..."
  else
    echo "Installing packages: ${to_install[*]}"
    sudo pacman -S --noconfirm "${to_install[@]}"
  fi
}

install_neovim() {
  NVIM_REPO="https://github.com/kiryl-kvit/nvim.git"
  NVIM_DIR="$HOME/.config/nvim"
  if [ ! -d "$NVIM_DIR" ]; then
    git clone "$NVIM_REPO" "$NVIM_DIR"
  else
    echo "Neovim config already exists at $NVIM_DIR, skipping..."
  fi
}

install_debian() {
  local apt_packages=(fzf fd-find ripgrep curl software-properties-common neovim)
  local to_install=()
  
  for pkg in "${apt_packages[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
      to_install+=("$pkg")
    fi
  done
  
  if [ ${#to_install[@]} -gt 0 ]; then
    sudo apt update
    sudo apt install -y "${to_install[@]}"
  else
    echo "All apt packages already installed..."
  fi

  if [ ! -e /usr/local/bin/fd ]; then
    if command -v fdfind >/dev/null 2>&1; then
      sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
    fi
  fi

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) DEB_ARCH="amd64" ;;
    aarch64|arm64) DEB_ARCH="arm64" ;;
  esac

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  if ! command -v zoxide >/dev/null 2>&1; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    sudo mv ~/.local/bin/zoxide /usr/local/bin/ 2>/dev/null || true
  else
    echo "zoxide already installed, skipping..."
  fi

  if ! command -v delta >/dev/null 2>&1; then
    DELTA_VERSION="$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
    curl -sL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${DEB_ARCH}.deb" -o "$TMPDIR/delta.deb"
    sudo dpkg -i "$TMPDIR/delta.deb"
  else
    echo "git-delta already installed, skipping..."
  fi

  if ! command -v fastfetch >/dev/null 2>&1; then
    FASTFETCH_VERSION="$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
    curl -sL "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-${DEB_ARCH}.deb" -o "$TMPDIR/fastfetch.deb"
    sudo dpkg -i "$TMPDIR/fastfetch.deb"
  else
    echo "fastfetch already installed, skipping..."
  fi

  if ! dpkg -l neovim 2>/dev/null | grep -q "^ii"; then
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y neovim
  fi

  FONT_DIR="/usr/local/share/fonts/nerd-fonts"
  if [ ! -d "$FONT_DIR" ] || [ -z "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
    TMP_ZIP="$(mktemp --suffix=.zip)"
    sudo mkdir -p "$FONT_DIR"
    curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -o "$TMP_ZIP"
    sudo unzip -o "$TMP_ZIP" -d "$FONT_DIR"
    rm -f "$TMP_ZIP"
    sudo fc-cache -fv
    fc-cache -fv
  else
    echo "FiraCode Nerd Font already installed, skipping..."
  fi
}

install_oh_my_zsh
install_starship

if command -v apt >/dev/null 2>&1; then
  install_debian
elif command -v pacman >/dev/null 2>&1; then
  install_arch
fi

install_neovim
