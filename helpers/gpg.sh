#!/usr/bin/env bash
# Description: Configure GPG with pinentry
# Usage: ./gpg.sh
#
# Actions:
#   - Installs GPG and pinentry-curses
#   - Creates ~/.gnupg/gpg-agent.conf
#   - Adds GPG_TTY export to shell rc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/distro.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

log_info "Installing GPG and pinentry..."
pkg_install gpg pinentry

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Auto-detect pinentry location
PINENTRY_PATH=$(command -v pinentry-curses || command -v pinentry-tty || command -v pinentry || true)
if [[ -z "$PINENTRY_PATH" ]]; then
  log_error "pinentry not found. Install pinentry-curses or pinentry."
  exit 1
fi

cat > ~/.gnupg/gpg-agent.conf <<EOF
allow-loopback-pinentry
pinentry-program $PINENTRY_PATH
EOF

gpgconf --kill gpg-agent

SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == */zsh ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "export GPG_TTY=" "$SHELL_RC"; then
  echo 'export GPG_TTY=$(tty)' >> "$SHELL_RC"
  log_info "Added GPG_TTY export to $SHELL_RC"
fi

export GPG_TTY=$(tty)
log_success "GPG configured"

