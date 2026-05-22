#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES/lib/common.sh"

ALL_MODULES=(claude zsh tmux nvim python npm iterm vscode)

usage() {
  cat <<EOF
Usage: $0 [--list] [--help] [MODULE...]

With no arguments, installs every module in canonical order plus the shared
prerequisites (Homebrew, nvm + Node LTS).

Pass module names to install only a subset, e.g.:
  $0 tmux zsh

To install a single module standalone (without the shared bootstrap), run
its installer directly:
  cd <module> && ./install.sh

Available modules:
  ${ALL_MODULES[*]}
EOF
}

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  --list)    printf '%s\n' "${ALL_MODULES[@]}"; exit 0 ;;
esac

if [[ $# -eq 0 ]]; then
  selected=("${ALL_MODULES[@]}")
else
  selected=("$@")
  for m in "${selected[@]}"; do
    found=0
    for known in "${ALL_MODULES[@]}"; do
      [[ "$m" == "$known" ]] && found=1 && break
    done
    if [[ $found -eq 0 ]]; then
      log_warn "Unknown module: $m"
      log_warn "Available: ${ALL_MODULES[*]}"
      exit 1
    fi
  done
fi

log_step "Bootstrapping dotfiles from $DOTFILES"
log_step "Modules: ${selected[*]}"

# Shared prerequisites used across multiple modules.
ensure_brew

if [[ ! -d "$HOME/.nvm" ]]; then
  log_step "Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | PROFILE=/dev/null bash
else
  log_ok "nvm already installed"
fi

# Ensure a Node binary is available (claude .mcp.json calls `npx`).
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
  if ! command -v node >/dev/null 2>&1; then
    log_step "Installing Node LTS via nvm"
    nvm install --lts
  else
    log_ok "node already installed"
  fi
fi

for m in "${selected[@]}"; do
  script="$DOTFILES/$m/install.sh"
  if [[ ! -x "$script" ]]; then
    log_warn "No installer for module '$m' at $script — skipping."
    continue
  fi
  "$script"
done

log_step "Done."
echo "  - Inside tmux, press: prefix + I  to install plugins."
echo "  - Open a new shell to pick up the new .zshrc."
