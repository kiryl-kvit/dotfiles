#!/usr/bin/env bash
# Description: Install WireGuard and generate keypair
# Usage: ./wireguard.sh [--uninstall]
#
# Options:
#   --uninstall    Remove WireGuard (prompts for key removal)
#
# Generated files:
#   /etc/wireguard/private.key
#   /etc/wireguard/public.key

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/distro.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

ACTION="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) 
      echo "Usage: $0 [--uninstall]"
      echo "  --uninstall    Remove WireGuard (prompts for key removal)"
      exit 0 
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

install_wireguard() {
  pkg_install wireguard

  wg genkey | sudo tee /etc/wireguard/private.key
  sudo chmod 600 /etc/wireguard/private.key
  sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

  log_success "WireGuard installed"
  echo "Private key: /etc/wireguard/private.key"
  echo "Public key: /etc/wireguard/public.key"
}

uninstall_wireguard() {
  log_info "Uninstalling WireGuard..."

  pkg_remove wireguard

  if [[ -d /etc/wireguard ]]; then
    if confirm "Remove WireGuard keys and configs (/etc/wireguard)?"; then
      sudo rm -rf /etc/wireguard
      log_info "WireGuard configuration removed"
    else
      log_info "WireGuard keys preserved in /etc/wireguard"
    fi
  fi

  log_success "WireGuard uninstalled"
}

case "$ACTION" in
  install) install_wireguard ;;
  uninstall) uninstall_wireguard ;;
esac
