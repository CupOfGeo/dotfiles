#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing nvim module"

brew_bundle_if_present "$MODULE_DIR"

link "$MODULE_DIR" "$HOME/.config/nvim"

log_step "nvim module installed"
echo "  Launch nvim; lazy.nvim will self-bootstrap and install plugins."
