#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

require_macos
log_step "Installing apps module"

brew_bundle_if_present "$MODULE_DIR"

# Let `docker compose` (v2 subcommand) find brew's docker-compose plugin.
link "$(brew --prefix)/opt/docker-compose/bin/docker-compose" \
     "$HOME/.docker/cli-plugins/docker-compose"

# Colima VM settings (cpu/memory/disk). Link before the service starts so a
# fresh machine boots the VM with these values; resource changes need a
# `colima stop` + `colima start` to take effect.
link "$MODULE_DIR/colima.yaml" "$HOME/.colima/default/colima.yaml"

# Start the colima docker VM at login. Guard on the loaded launchd job, not
# `brew services list` — it reports colima "stopped" because `colima start`
# exits once the VM is up, and re-bootstrapping a loaded job fails.
if launchctl print "gui/$(id -u)/homebrew.mxcl.colima" >/dev/null 2>&1; then
  log_ok "colima login service already registered"
else
  log_step "Registering colima as a login service"
  brew services start colima
fi

# llm-redact-proxy settings (install.key stays local: it's the per-install
# placeholder hash key). Restart the service to apply:
# `brew services restart llm-redact-proxy`.
link "$MODULE_DIR/redact-proxy.toml" "$HOME/.config/llm-redact-proxy/config.toml"

# Headroom compression proxy on :8788, behind llm-redact-proxy (:8787 upstream).
# Copied, not linked: launchd is unreliable about symlinked plists at login.
# Re-run after editing the plist.
if [[ -x "$HOME/.local/bin/headroom" ]]; then
  plist="$HOME/Library/LaunchAgents/ai.headroom.proxy.plist"
  cp "$MODULE_DIR/ai.headroom.proxy.plist" "$plist"
  launchctl bootout "gui/$(id -u)/ai.headroom.proxy" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
  log_ok "headroom proxy login service"
else
  log_warn "headroom not installed; skipping (uv tool install --python 3.13 'headroom-ai[proxy,code,ml]')"
fi

# Restart redact-proxy only when its running upstream differs from the config,
# and never before that upstream answers — else every session fails closed.
want=$(sed -nE 's/^upstream = "([^"]+)".*/\1/p' "$MODULE_DIR/redact-proxy.toml")
have=$(curl -sf -m3 http://127.0.0.1:8787/health | jq -r '.upstream // empty' || true)
if [[ "$have" == "$want" ]]; then
  log_ok "redact-proxy upstream $want"
elif ! curl -s -o /dev/null -m3 --retry 30 --retry-delay 1 --retry-connrefused "$want/health"; then
  log_warn "$want not answering; redact-proxy left on ${have:-<down>}"
else
  brew services restart llm-redact-proxy
  log_ok "redact-proxy restarted -> $want"
fi

log_step "apps module installed"
echo "  - Open Tailscale.app and log in to join your tailnet."
echo "  - colima runs as a login service; docker/compose just work."
