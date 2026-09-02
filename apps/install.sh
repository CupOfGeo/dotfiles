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

# Start the colima docker VM at login. Guard on the loaded launchd job, not
# `brew services list` — it reports colima "stopped" because `colima start`
# exits once the VM is up, and re-bootstrapping a loaded job fails.
if launchctl print "gui/$(id -u)/homebrew.mxcl.colima" >/dev/null 2>&1; then
  log_ok "colima login service already registered"
else
  log_step "Registering colima as a login service"
  brew services start colima
fi

log_step "apps module installed"
echo "  - Open Tailscale.app and log in to join your tailnet."
echo "  - colima runs as a login service; docker/compose just work."
