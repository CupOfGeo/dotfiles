#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Bootstrapping dotfiles from $DOTFILES"

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. Brewfile packages
echo "==> Installing Brewfile packages"
brew bundle --file="$DOTFILES/Brewfile"

# 3. TPM (tmux plugin manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "==> Cloning TPM"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "==> TPM already installed"
fi

# 4. oh-my-zsh + custom theme/plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "==> oh-my-zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "==> Cloning powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

AUTOSUG_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ ! -d "$AUTOSUG_DIR" ]; then
  echo "==> Cloning zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG_DIR"
fi

# 5. nvm (Node version manager)
if [ ! -d "$HOME/.nvm" ]; then
  echo "==> Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | PROFILE=/dev/null bash
else
  echo "==> nvm already installed"
fi

# 6. uv (Python version + project manager) + Python versions
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Make uv available for the rest of this script
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -f "$DOTFILES/python/versions.txt" ]; then
  echo "==> Installing Python versions via uv"
  while IFS= read -r version; do
    [ -z "$version" ] && continue
    case "$version" in \#*) continue ;; esac
    uv python install "$version"
  done < "$DOTFILES/python/versions.txt"
fi

# 7. Symlink configs
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "    ok  $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%s)"
    echo "    backed up existing $dest"
  fi
  ln -s "$src" "$dest"
  echo "    linked $dest -> $src"
}

echo "==> Linking configs"
link "$DOTFILES/tmux/tmux.conf"  "$HOME/.tmux.conf"
link "$DOTFILES/zsh/zshrc"       "$HOME/.zshrc"
link "$DOTFILES/zsh/p10k.zsh"    "$HOME/.p10k.zsh"
link "$DOTFILES/python/uv.toml"  "$HOME/.config/uv/uv.toml"
link "$DOTFILES/ghostty/config"  "$HOME/.config/ghostty/config"

echo ""
echo "Done."
echo "  - Inside tmux, press: prefix + I  to install plugins."
echo "  - Open a new shell to pick up the new .zshrc."
