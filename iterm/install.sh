#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

require_macos
log_step "Installing iterm module"

brew_bundle_if_present "$MODULE_DIR"

log_step "Configuring iTerm2 to load prefs from dotfiles"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$MODULE_DIR"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

log_step "iterm module installed"
