#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

log_step "Installing claude module"

brew_bundle_if_present "$MODULE_DIR"

link "$MODULE_DIR/settings.json" "$HOME/.claude/settings.json"
link "$MODULE_DIR/.mcp.json"     "$HOME/.claude/.mcp.json"
link "$MODULE_DIR/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$MODULE_DIR/LSP.md"        "$HOME/.claude/LSP.md"
link "$MODULE_DIR/RTK.md"        "$HOME/.claude/RTK.md"

# media-hook.sh is intentionally NOT symlinked. zshrc sources it directly
# from the dotfiles path.

# Global npm-installed LSP servers (Node provided by the top-level installer).
if command -v npm >/dev/null 2>&1; then
  log_step "Installing global npm LSP packages"
  npm i -g pyright >/dev/null
  log_ok "pyright"
  npm i -g typescript-language-server typescript >/dev/null
  log_ok "typescript-language-server + typescript"
else
  log_warn "npm not on PATH — skipping pyright + typescript-language-server"
  log_warn "Run the top-level install.sh first to bootstrap Node via nvm."
fi

# Claude Code LSP plugins.
if command -v claude >/dev/null 2>&1; then
  log_step "Updating claude-plugins-official marketplace + installing LSP plugins"
  claude plugin marketplace update claude-plugins-official
  claude plugin install pyright-lsp
  claude plugin install typescript-lsp
  # Uncomment for Go support (also uncomment `brew "gopls"` in claude/Brewfile).
  # claude plugin install gopls-lsp
else
  log_warn "claude CLI not on PATH — skipping plugin installs"
fi

log_step "claude module installed"
echo "  Other marketplaces in settings.json's enabledPlugins list still need"
echo "  /plugin marketplace add inside Claude Code to activate."
