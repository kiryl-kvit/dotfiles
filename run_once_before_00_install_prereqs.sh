#!/usr/bin/env bash

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
  sudo pacman -S --noconfirm zoxide fzf fd ripgrep git-delta fastfetch neovim ttf-firacode-nerd vivid lazygit wl-clipboard
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
  aarch64 | arm64) DEB_ARCH="arm64" ;;
  esac

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    echo "Homebrew already installed, skipping..."
  fi

  if ! command -v lazygit >/dev/null 2>&1; then
    brew install lazygit
  else
    echo "lazygit already installed, skipping..."
  fi

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

  if ! command -v vivid >/dev/null 2>&1; then
    TAG=$(curl -s https://api.github.com/repos/sharkdp/vivid/releases/latest | jq -r .tag_name)
    # find the first .deb whose name contains the arch string
    ASSET_URL=$(curl -s "https://api.github.com/repos/sharkdp/vivid/releases/tags/${TAG}" |
      jq -r --arg arch "$DEB_ARCH" '.assets[] 
        | select(.name | test("\\.deb$") and (test($arch))) 
        | .browser_download_url' |
      head -n1)

    if [ -z "$ASSET_URL" ]; then
      echo "No .deb asset found for architecture: $DEB_ARCH in release $TAG" >&2
      echo "Available assets:" >&2
      curl -s "https://api.github.com/repos/sharkdp/vivid/releases/tags/${TAG}" |
        jq -r '.assets[].name' >&2
      exit 1
    fi

    echo "Downloading $ASSET_URL ..."
    curl -fSL "$ASSET_URL" -o "$TMPDIR/vivid.deb"
    sudo dpkg -i "$TMPDIR/vivid.deb"
  else
    echo "vivid already installed, skipping..."
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

install_starship

if command -v apt >/dev/null 2>&1; then
  install_debian
elif command -v pacman >/dev/null 2>&1; then
  install_arch
fi
