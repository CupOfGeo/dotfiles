#!/usr/bin/env bash
# Shared helpers for dotfiles install scripts. Source this; don't execute it.

[[ -n "${_DOTFILES_COMMON_SH:-}" ]] && return 0
_DOTFILES_COMMON_SH=1

log_step() { printf '==> %s\n' "$*"; }
log_ok()   { printf '    ok  %s\n' "$*"; }
log_warn() { printf 'WARN: %s\n' "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "This module is macOS-only; skipping."
    exit 0
  fi
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  log_step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_bundle_if_present() {
  local dir="$1"
  [[ -f "$dir/Brewfile" ]] || return 0
  ensure_brew
  log_step "Installing Brewfile packages in $dir"
  brew bundle --file="$dir/Brewfile"
}

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" = "$src" ]]; then
    log_ok "$dest"
    return
  fi
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    mv "$dest" "$dest.backup.$(date +%s)"
    log_ok "backed up existing $dest"
  fi
  ln -s "$src" "$dest"
  log_ok "linked $dest -> $src"
}
