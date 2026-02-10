#!/usr/bin/env bash
# Description: Install Docker CE with compose plugin
# Usage: ./docker.sh [--uninstall]
#
# Options:
#   --uninstall    Remove Docker and optionally Docker data
#
# Actions:
#   - Adds Docker official repository
#   - Installs Docker CE, CLI, containerd, buildx, compose
#   - Adds current user to docker group

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
      echo "  --uninstall    Remove Docker and optionally Docker data"
      exit 0 
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

install_docker_debian() {
  $PKG_UPDATE
  $PKG_INSTALL ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL "https://download.docker.com/linux/$DISTRO_ID/gpg" -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(get_arch) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DISTRO_ID \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  $PKG_UPDATE
  $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_fedora() {
  sudo dnf -y install dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl start docker
  sudo systemctl enable docker
}

install_docker_arch() {
  $PKG_INSTALL docker docker-compose
  sudo systemctl start docker
  sudo systemctl enable docker
}

install_docker() {
  case "$DISTRO_FAMILY" in
    debian) install_docker_debian ;;
    fedora) install_docker_fedora ;;
    arch)   install_docker_arch ;;
    *)      log_error "Unsupported distro: $DISTRO_FAMILY"; exit 1 ;;
  esac

  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    log_warn "Added $USER to docker group. Log out and back in for changes to take effect."
  fi

  log_success "Docker installed successfully"
}

uninstall_docker() {
  log_info "Uninstalling Docker..."

  # Stop services
  sudo systemctl stop docker.socket docker.service 2>/dev/null || true
  sudo systemctl disable docker.socket docker.service 2>/dev/null || true

  case "$DISTRO_FAMILY" in
    debian)
      sudo apt remove -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
      sudo rm -f /etc/apt/sources.list.d/docker.list
      sudo rm -f /etc/apt/keyrings/docker.asc
      ;;
    fedora)
      sudo dnf remove -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
      sudo rm -f /etc/yum.repos.d/docker-ce.repo
      ;;
    arch)
      sudo pacman -Rns --noconfirm docker docker-compose 2>/dev/null || true
      ;;
  esac

  # Remove user from docker group
  sudo gpasswd -d "$USER" docker 2>/dev/null || true

  if confirm "Remove Docker data (/var/lib/docker)?"; then
    sudo rm -rf /var/lib/docker /var/lib/containerd
    log_info "Docker data removed"
  fi

  log_success "Docker uninstalled"
}

case "$ACTION" in
  install) install_docker ;;
  uninstall) uninstall_docker ;;
esac
