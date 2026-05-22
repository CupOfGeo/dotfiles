#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing tmux module"

brew_bundle_if_present "$MODULE_DIR"

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  log_step "Cloning TPM"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  log_ok "TPM already installed"
fi

link "$MODULE_DIR/tmux.conf" "$HOME/.tmux.conf"

log_step "tmux module installed"
echo "  Inside tmux, press prefix + I to install plugins."
