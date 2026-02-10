#!/usr/bin/env bash
# Description: Install Cloudflare Tunnel client
# Usage: ./cloudflared.sh [--uninstall]
#
# Options:
#   --uninstall    Remove cloudflared
#
# Installation method:
#   - Debian: .deb from GitHub releases
#   - Fedora: .rpm from GitHub releases
#   - Arch: AUR via yay

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/distro.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

ACTION="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) 
      echo "Usage: $0 [--uninstall]"
      echo "  --uninstall    Remove cloudflared"
      exit 0 
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

ARCH=$(get_arch)

case "$ARCH" in
  amd64|arm64) CF_ARCH="$ARCH" ;;
  arm) CF_ARCH="arm" ;;
  *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

install_cloudflared_debian() {
  local pkg="cloudflared-linux-${CF_ARCH}.deb"
  local url="https://github.com/cloudflare/cloudflared/releases/latest/download/${pkg}"
  
  log_info "Downloading $pkg..."
  download "$url" "/tmp/$pkg"
  sudo dpkg -i "/tmp/$pkg"
  rm -f "/tmp/$pkg"
}

install_cloudflared_fedora() {
  local pkg="cloudflared-linux-${CF_ARCH}.rpm"
  local url="https://github.com/cloudflare/cloudflared/releases/latest/download/${pkg}"
  
  log_info "Downloading $pkg..."
  download "$url" "/tmp/$pkg"
  sudo rpm -i "/tmp/$pkg"
  rm -f "/tmp/$pkg"
}

install_cloudflared_arch() {
  log_info "Installing from AUR (requires yay or manual install)"
  if command -v yay &>/dev/null; then
    yay -S --noconfirm cloudflared
  else
    log_error "yay not found. Install cloudflared manually from AUR"
    exit 1
  fi
}

install_cloudflared() {
  case "$DISTRO_FAMILY" in
    debian) install_cloudflared_debian ;;
    fedora) install_cloudflared_fedora ;;
    arch)   install_cloudflared_arch ;;
    *)      log_error "Unsupported distro: $DISTRO_FAMILY"; exit 1 ;;
  esac

  cloudflared --version
  log_success "cloudflared installed"
}

uninstall_cloudflared() {
  log_info "Uninstalling cloudflared..."

  case "$DISTRO_FAMILY" in
    debian)
      sudo apt remove -y cloudflared 2>/dev/null || true
      ;;
    fedora)
      sudo rpm -e cloudflared 2>/dev/null || true
      ;;
    arch)
      if command -v yay &>/dev/null; then
        yay -Rns --noconfirm cloudflared 2>/dev/null || true
      else
        log_warn "yay not found. Remove cloudflared manually from AUR"
      fi
      ;;
  esac

  log_success "cloudflared uninstalled"
}

case "$ACTION" in
  install) install_cloudflared ;;
  uninstall) uninstall_cloudflared ;;
esac

