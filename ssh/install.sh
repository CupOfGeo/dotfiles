#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/.." && pwd)"
source "$DOTFILES/lib/common.sh"

SSHD_DROPIN="/etc/ssh/sshd_config.d/010-dotfiles.conf"

log_step "Installing ssh module"

# ---------------------------------------------------------------------------
# Client side: config, key, agent. Safe and non-privileged.
# ---------------------------------------------------------------------------

mkdir -p "$HOME/.ssh/control"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/control"

link "$MODULE_DIR/config" "$HOME/.ssh/config"

# Machine-local override file the tracked config Includes. Personal host entries
# (tailnet machines, work boxes, jump hosts) belong here rather than in the repo,
# so a shared clone carries no one's private topology.
if [[ ! -e "$HOME/.ssh/config.local" ]]; then
  cat > "$HOME/.ssh/config.local" <<'LOCAL'
# Machine-local SSH overrides. NOT tracked by dotfiles.
# Included first by ~/.ssh/config, so anything here wins over the shared
# defaults (OpenSSH keeps the first value it obtains for a keyword).
#
# Example:
#   Host myserver
#     HostName myserver.example.ts.net
#     User me
LOCAL
  chmod 600 "$HOME/.ssh/config.local"
  log_ok "created ~/.ssh/config.local"
fi

# Outbound identity for this machine. The private half is generated here and
# never enters the repo; only the .pub is meant to be shared.
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  log_step "Generating ed25519 key for $(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" \
    -C "$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
else
  log_ok "~/.ssh/id_ed25519 already exists"
fi
ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null \
  && log_ok "key loaded into ssh-agent + Keychain" \
  || log_warn "could not add key to agent (is ssh-agent running?)"

# ---------------------------------------------------------------------------
# Server side: only reached if there is at least one key that could log in.
# ---------------------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
  log_ok "not macOS; skipping sshd server setup"
  log_step "ssh module installed"
  exit 0
fi

# authorized_keys IS tracked in this repo, because having your own machines'
# public keys here is what makes a fresh install immediately reachable. The
# hazard is that anyone ELSE installing these dotfiles would silently grant
# those keys a login on their machine -- so show exactly whose keys are about
# to be authorized and make it a deliberate choice.
AUTH_SRC="$MODULE_DIR/authorized_keys"

# Count real key lines (ignore comments/blanks).
key_count=$(grep -cvE '^[[:space:]]*(#|$)' "$AUTH_SRC" || true)

if [[ "$key_count" -eq 0 ]]; then
  log_warn "$AUTH_SRC contains no public keys."
  log_warn "Skipping sshd setup: enabling key-only SSH with no authorized keys"
  log_warn "would leave a server nothing can log into."
  log_warn ""
  log_warn "Add a key by running this ON THE MACHINE YOU WANT TO CONNECT FROM:"
  log_warn "    cat ~/.ssh/id_ed25519.pub"
  log_warn "append the line to $AUTH_SRC, then re-run this."
  log_step "ssh module installed (client side only)"
  exit 0
fi

printf '\n'
log_step "These keys will be granted SSH login to this machine:"
# Print type + comment (last field), never the key body -- the comment is the
# part that tells you whose key it is.
grep -vE '^[[:space:]]*(#|$)' "$AUTH_SRC" | while read -r type _ comment; do
  printf '      %-12s %s\n' "$type" "${comment:-(no comment -- unidentified key)}"
done
printf '\n'

if [[ "${DOTFILES_SSH_ASSUME_YES:-}" == "1" ]]; then
  log_ok "DOTFILES_SSH_ASSUME_YES=1; proceeding without prompting"
elif [[ -t 0 ]]; then
  read -r -p "    Authorize these keys on this machine? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_warn "Declined. No SSH server changes made."
    log_step "ssh module installed (client side only)"
    exit 0
  fi
else
  log_warn "Not running interactively and DOTFILES_SSH_ASSUME_YES is unset."
  log_warn "Refusing to authorize keys unattended. Re-run in a terminal, or set"
  log_warn "DOTFILES_SSH_ASSUME_YES=1 if you are sure these keys are yours."
  log_step "ssh module installed (client side only)"
  exit 0
fi

link "$AUTH_SRC" "$HOME/.ssh/authorized_keys"
log_ok "$key_count authorized key(s)"

# macOS creates /etc/ssh/ssh_host_* lazily: sshd-keygen-wrapper generates them
# the first time Remote Login starts sshd. We validate with `sshd -t` BEFORE
# enabling Remote Login, and sshd -t refuses to run without host keys ("no
# hostkeys available -- exiting"), so generate them up front. ssh-keygen -A
# creates only what is missing and is safe to re-run.
#
# Order matters: host keys -> drop-in -> validate -> enable. Enabling first
# would also generate the keys, but would briefly run sshd with password auth
# still allowed.
if ! sudo test -f /etc/ssh/ssh_host_ed25519_key; then
  log_step "Generating sshd host keys (requires sudo)"
  sudo ssh-keygen -A
  log_ok "host keys created in /etc/ssh"
else
  log_ok "sshd host keys already present"
fi

# The drop-in is COPIED, not symlinked. sshd reads it as root; a symlink into a
# user-writable repo would let anyone who can write ~/dotfiles change the SSH
# server's config. Copy it root-owned instead.
log_step "Installing sshd drop-in (requires sudo)"
tmp="$(mktemp)"
sed "s/^AllowUsers .*/AllowUsers $(whoami)/" \
  "$MODULE_DIR/sshd_config.d/010-dotfiles.conf" > "$tmp"

# Stash whatever is live so a bad config can be rolled back.
backup=""
if sudo test -f "$SSHD_DROPIN"; then
  backup="$(mktemp)"
  sudo cp "$SSHD_DROPIN" "$backup"
fi

sudo install -m 644 -o root -g wheel "$tmp" "$SSHD_DROPIN"
rm -f "$tmp"

# Validate the merged config. On failure, put back exactly what was there.
if ! sudo sshd -t; then
  if [[ -n "$backup" ]]; then
    sudo install -m 644 -o root -g wheel "$backup" "$SSHD_DROPIN"
    rm -f "$backup"
    log_warn "sshd config invalid; rolled back to the previous drop-in."
  else
    sudo rm -f "$SSHD_DROPIN"
    log_warn "sshd config invalid; removed the drop-in. Nothing changed."
  fi
  exit 1
fi
[[ -n "$backup" ]] && rm -f "$backup" || true
log_ok "$SSHD_DROPIN validates"

log_step "Enabling Remote Login"

# systemsetup needs the calling terminal to hold Full Disk Access, which a fresh
# machine will not have. Do not trust its exit code either -- it prints errors
# and still returns 0. Attempt, then verify by looking for the listening socket.
out="$(sudo systemsetup -setremotelogin on 2>&1 || true)"
printf '%s' "$out" | grep -qi 'Full Disk Access' && needs_fda=1 || needs_fda=0

# Verify with a real TCP connect, NOT `lsof`: launchd holds the port-22 socket
# as root, and an unprivileged lsof cannot see it -- so lsof reports "nothing
# listening" even when sshd is up and answering.
if nc -z -G 2 -w 2 127.0.0.1 22 >/dev/null 2>&1; then
  sudo launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
  log_ok "Remote Login is on; sshd is listening"
else
  log_warn "Could not enable Remote Login automatically."
  if [[ $needs_fda -eq 1 ]]; then
    log_warn "macOS requires Full Disk Access for this terminal to toggle it."
  fi
  log_warn ""
  log_warn "Everything else IS installed: authorized keys, host keys, and the"
  log_warn "hardened drop-in. Only the service switch is left. Do one of:"
  log_warn "  a) System Settings > General > Sharing > Remote Login  (toggle on)"
  log_warn "  b) Give this terminal Full Disk Access in System Settings >"
  log_warn "     Privacy & Security, then re-run this installer"
  log_warn "  c) sudo launchctl enable system/com.openssh.sshd &&"
  log_warn "     sudo launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist"
  log_warn ""
  log_warn "The drop-in is already active, so SSH is key-only the moment it comes"
  log_warn "up -- there is no window where passwords are accepted."
  log_step "ssh module installed (Remote Login still off)"
  exit 0
fi
log_step "ssh module installed"
printf '\n    Reach this machine over the tailnet with:\n'
ts_name="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null | sed 's/\.$//')"
printf '        ssh %s@%s\n\n' "$(whoami)" "${ts_name:-<tailnet-name>}"
