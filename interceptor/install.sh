#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

# Interceptor — drive a signed-in browser session from a CLI (built for AI
# agents). Not in Homebrew; installed from the project's signed, notarized
# .pkg. After the first install it self-updates via Sparkle, so bumping the
# pin here only matters for fresh machines.
#
# To upgrade the pinned bootstrap version:
#   1. VERSION below -> new release tag (without the leading 'v').
#   2. Confirm the pkg asset name still matches PKG_NAME.
# Signed by: HACKER VALLEY MEDIA, LLC (Apple Team ID TPWBZD35WW).
VERSION="0.23.20"
TEAM_ID="TPWBZD35WW"
PKG_NAME="Interceptor-Browser-${VERSION}.pkg"
BASE_URL="https://github.com/Hacker-Valley-Media/Interceptor/releases/download/v${VERSION}"

require_macos
log_step "Installing interceptor module (v${VERSION}, browser-only)"

# --- 1. Install the pkg (idempotent: skip if the pinned version is present) ---
if command -v interceptor >/dev/null 2>&1 && interceptor --version 2>/dev/null | grep -q "$VERSION"; then
  log_ok "interceptor ${VERSION} already installed"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  log_step "Downloading ${PKG_NAME}"
  curl -fsSL -o "$tmp/$PKG_NAME"   "$BASE_URL/$PKG_NAME"
  curl -fsSL -o "$tmp/SHA256SUMS"  "$BASE_URL/SHA256SUMS"

  log_step "Verifying checksum"
  ( cd "$tmp" && grep "$PKG_NAME" SHA256SUMS | shasum -a 256 -c - ) \
    || { log_warn "Checksum mismatch for $PKG_NAME — aborting."; exit 1; }

  log_step "Verifying signature + notarization"
  sig="$(pkgutil --check-signature "$tmp/$PKG_NAME" 2>/dev/null || true)"
  if ! grep -q "$TEAM_ID" <<<"$sig" || ! grep -qi "notariz" <<<"$sig"; then
    log_warn "Signature check failed (expected Team ID $TEAM_ID + notarization) — aborting."
    exit 1
  fi

  log_step "Installing pkg (requires sudo)"
  sudo installer -pkg "$tmp/$PKG_NAME" -target /

  rm -rf "$tmp"
  trap - EXIT
  log_ok "interceptor installed: $(interceptor --version 2>/dev/null || echo '(re-open shell)')"
fi

# --- 2. Adopt Interceptor's skill packs into Claude Code (idempotent) ---
# Symlinks the shipped playbooks into ~/.claude/skills so agents drive the
# tool fluently. Depends on the interceptor binary, which is why it lives
# here and not in the claude/ module.
if command -v interceptor >/dev/null 2>&1; then
  log_step "Adopting interceptor skill packs into Claude Code"
  interceptor skills adopt --into claude || log_warn "skills adopt failed (non-fatal)"
fi

# --- 3. The one step no installer can do for you ---
log_step "interceptor module installed"
cat <<'EOF'
    ok  MANUAL STEP — load the browser extension (Brave/Chrome block
        programmatic unpacked-extension loads outside the Web Store):
          1. Open  brave://extensions/   (or chrome://extensions/)
          2. Enable Developer mode (top-right)
          3. Click "Load unpacked"
          4. Select  /Library/Application Support/Interceptor/extension/
        Then verify end-to-end:  interceptor open "https://example.com"
        Native macOS/iPhone control (not installed):  interceptor upgrade --full
EOF
