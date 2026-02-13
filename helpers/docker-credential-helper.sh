#!/usr/bin/env bash
# Description: Install Docker credential helper using pass
# Usage: ./docker-credential-helper.sh [--uninstall]
#
# Options:
#   --uninstall    Remove credential helper binary
#
# Prerequisites: pass (password manager) should be configured
# Configures: ~/.docker/config.json with credsStore: "pass"

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
      echo "  --uninstall    Remove credential helper binary"
      exit 0 
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

install_docker_credential_helper() {
  read -rp "Enter version (default 0.9.5): " VERSION
  VERSION=${VERSION:-0.9.5}

  ARCH=$(get_arch)
  case "$ARCH" in
    amd64|arm64) ;;
    *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
  esac

  BIN_NAME="docker-credential-pass-v${VERSION}.linux-${ARCH}"
  DOWNLOAD_URL="https://github.com/docker/docker-credential-helpers/releases/latest/download/${BIN_NAME}"

  log_info "Installing docker-credential-pass..."

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  pushd "$TMPDIR" >/dev/null

  log_info "Downloading ${BIN_NAME}..."
  download "$DOWNLOAD_URL" "$BIN_NAME"

  chmod +x "$BIN_NAME"
  sudo mv "$BIN_NAME" /usr/local/bin/docker-credential-pass

  popd >/dev/null

  CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
  CONFIG_FILE="$CONFIG_DIR/config.json"

  mkdir -p "$CONFIG_DIR"

  # Handle Docker config
  if [[ ! -f "$CONFIG_FILE" ]] || [[ ! -s "$CONFIG_FILE" ]]; then
    # File doesn't exist or is empty - create new config
    echo '{"credsStore": "pass"}' > "$CONFIG_FILE"
    log_info "Created new Docker config"
  elif command -v jq &>/dev/null; then
    # Use jq to safely merge into existing config
    tmp=$(mktemp)
    if jq -e . "$CONFIG_FILE" &>/dev/null; then
      jq '. + {"credsStore": "pass"}' "$CONFIG_FILE" > "$tmp"
      mv "$tmp" "$CONFIG_FILE"
      log_info "Updated existing Docker config"
    else
      log_error "Existing config is not valid JSON: $CONFIG_FILE"
      rm -f "$tmp"
      exit 1
    fi
  else
    log_error "jq is required to modify existing Docker config"
    log_info "Install jq and retry, or manually add '\"credsStore\": \"pass\"' to $CONFIG_FILE"
    exit 1
  fi

  log_success "Docker configured to use 'pass' credential helper"
}

uninstall_docker_credential_helper() {
  log_info "Uninstalling docker-credential-pass..."

  sudo rm -f /usr/local/bin/docker-credential-pass

  CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
  CONFIG_FILE="$CONFIG_DIR/config.json"

  if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
    if confirm "Remove credsStore from Docker config?"; then
      tmp=$(mktemp)
      jq 'del(.credsStore)' "$CONFIG_FILE" > "$tmp"
      mv "$tmp" "$CONFIG_FILE"
      log_info "Removed credsStore from Docker config"
    fi
  fi

  log_success "docker-credential-pass uninstalled"
}

case "$ACTION" in
  install) install_docker_credential_helper ;;
  uninstall) uninstall_docker_credential_helper ;;
esac

