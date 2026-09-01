#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

require_macos
log_step "Installing brave module"

brew_bundle_if_present "$MODULE_DIR"

log_step "brave module installed"
echo "  Extensions are installed manually from the Web Store."
echo "  Interceptor's unpacked extension also loads manually (see interceptor/README.md)."
