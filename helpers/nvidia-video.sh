#!/usr/bin/env bash
# Description: Install NVIDIA VA-API/VDPAU video acceleration drivers
# Usage: ./nvidia-video.sh [--uninstall]
#
# Options:
#   --uninstall    Remove video acceleration packages
#
# Installs: vainfo, vdpauinfo, libvdpau-va-gl, nvidia-vaapi-driver

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
      echo "  --uninstall    Remove video acceleration packages"
      exit 0 
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

install_nvidia_video() {
  case "$DISTRO_FAMILY" in
    debian)
      $PKG_UPDATE
      $PKG_INSTALL vainfo vdpauinfo libvdpau-va-gl1 nvidia-vaapi-driver
      ;;
    fedora)
      $PKG_UPDATE
      $PKG_INSTALL libva-utils vdpauinfo libvdpau-va-gl nvidia-vaapi-driver
      ;;
    arch)
      $PKG_INSTALL libva-utils vdpauinfo libvdpau-va-gl libva-nvidia-driver
      ;;
    *)
      log_error "Unsupported distro: $DISTRO_FAMILY"
      exit 1
      ;;
  esac

  log_success "NVIDIA video acceleration packages installed"
}

uninstall_nvidia_video() {
  log_info "Uninstalling NVIDIA video acceleration packages..."

  case "$DISTRO_FAMILY" in
    debian)
      sudo apt remove -y vainfo vdpauinfo libvdpau-va-gl1 nvidia-vaapi-driver 2>/dev/null || true
      ;;
    fedora)
      sudo dnf remove -y libva-utils vdpauinfo libvdpau-va-gl nvidia-vaapi-driver 2>/dev/null || true
      ;;
    arch)
      sudo pacman -Rns --noconfirm libva-utils vdpauinfo libvdpau-va-gl libva-nvidia-driver 2>/dev/null || true
      ;;
  esac

  log_success "NVIDIA video packages uninstalled"
}

case "$ACTION" in
  install) install_nvidia_video ;;
  uninstall) uninstall_nvidia_video ;;
esac
