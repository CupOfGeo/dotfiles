#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

require_macos
log_step "Installing vscode module"

VSCODE_USER="$HOME/Library/Application Support/Code/User"
link "$MODULE_DIR/settings.json"    "$VSCODE_USER/settings.json"
link "$MODULE_DIR/keybindings.json" "$VSCODE_USER/keybindings.json"

if command -v code >/dev/null 2>&1 && [[ -f "$MODULE_DIR/extensions.txt" ]]; then
  log_step "Installing VSCode extensions"
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    case "$ext" in \#*) continue ;; esac
    code --install-extension "$ext" --force >/dev/null
    log_ok "installed $ext"
  done < "$MODULE_DIR/extensions.txt"
else
  log_warn "Skipping VSCode extensions ('code' CLI not on PATH)"
fi

log_step "vscode module installed"
