#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing python module"

if ! command -v uv >/dev/null 2>&1; then
  log_step "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  log_ok "uv already installed"
fi

if [[ -f "$MODULE_DIR/versions.txt" ]]; then
  log_step "Installing Python versions via uv"
  while IFS= read -r version; do
    [[ -z "$version" ]] && continue
    case "$version" in \#*) continue ;; esac
    uv python install "$version"
  done < "$MODULE_DIR/versions.txt"
fi

link "$MODULE_DIR/uv.toml" "$HOME/.config/uv/uv.toml"

log_step "python module installed"
