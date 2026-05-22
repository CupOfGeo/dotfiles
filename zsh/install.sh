#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing zsh module"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_step "Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log_ok "oh-my-zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
  log_step "Cloning powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  log_ok "powerlevel10k already installed"
fi

AUTOSUG_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [[ ! -d "$AUTOSUG_DIR" ]]; then
  log_step "Cloning zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG_DIR"
else
  log_ok "zsh-autosuggestions already installed"
fi

link "$MODULE_DIR/zshrc"    "$HOME/.zshrc"
link "$MODULE_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# aliases.sh is sourced from zshrc by absolute dotfiles path — no symlink.

if [[ ! -r "$DOTFILES/claude/media-hook.sh" ]]; then
  log_warn "claude/media-hook.sh not found; the 'media-hook' function will be unavailable in your shell."
fi

log_step "zsh module installed"
echo "  Open a new shell to pick up the new .zshrc."
