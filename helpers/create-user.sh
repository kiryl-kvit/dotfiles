#!/usr/bin/env bash
# Description: Create a new sudo user with SSH directory
# Usage: ./create-user.sh [username]
# Requires: root
#
# Actions:
#   - Creates user with bash shell
#   - Adds to sudo/wheel group
#   - Sets up ~/.ssh directory
#   - Forces password change on first login

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/distro.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

require_root

if [[ -z "${1:-}" ]]; then
  log_error "Usage: $0 <username>"
  exit 1
fi
USERNAME="$1"

useradd -m -s /bin/bash "$USERNAME"
usermod -aG "$SUDO_GROUP" "$USERNAME"
chage -d 0 "$USERNAME"

mkdir -p "/home/$USERNAME/.ssh"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
chmod 700 "/home/$USERNAME/.ssh"
touch "/home/$USERNAME/.ssh/authorized_keys"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

log_success "User $USERNAME created with $SUDO_GROUP group"
log_warn "Don't forget to add ssh key to authorized_keys"
