#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing npm module"

# nvm bootstrap lives in the top-level install.sh because Node is a shared
# runtime dependency (e.g., claude's .mcp.json runs `npx ...`).
if [[ ! -d "$HOME/.nvm" ]]; then
  log_warn "nvm is not installed. Run the top-level install.sh to bootstrap it."
fi

link "$MODULE_DIR/npmrc" "$HOME/.npmrc"

log_step "npm module installed"
