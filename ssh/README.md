# ssh

Two halves that happen to share a directory:

- **Client** (`config`) — how this machine reaches *other* hosts. Symlinked to
  `~/.ssh/config`.
- **Server** (`sshd_config.d/010-dotfiles.conf`, `authorized_keys`) — how *other*
  machines reach this one. This is the half that lets me SSH in from my
  MacBook Pro, `home`, etc.

## What is and isn't in this repo

| Tracked | Not tracked |
| --- | --- |
| `config` — shared client defaults | `~/.ssh/config.local` — my host entries |
| `sshd_config.d/*.conf` — server rules | `~/.ssh/id_ed25519` — private key |
| `authorized_keys` — **public** keys allowed in | |

Private keys are excluded because they are secrets. `.gitignore` lists
`id_ed25519` / `id_rsa` explicitly, because the pre-existing `*_key*` / `*.key` /
`*.pem` patterns do **not** match OpenSSH's default key filenames.

`authorized_keys` **is** tracked. Public keys are not secrets, and keeping them
here is what makes a freshly-installed machine reachable from my others right
away. The real hazard is not disclosure but inheritance: if someone else
installs these dotfiles, those keys would get a login on *their* machine. So
`install.sh` prints whose keys it is about to authorize and waits for a `y`:

```
==> These keys will be granted SSH login to this machine:
      ssh-ed25519  george@macbook-pro
      ssh-ed25519  george@home

    Authorize these keys on this machine? [y/N]
```

One keypress for me; an obvious stop sign for anyone else. Set
`DOTFILES_SSH_ASSUME_YES=1` to skip it. Run non-interactively without that
variable and it refuses rather than authorizing keys unattended.

Always give a key a trailing comment naming its machine — that comment is what
the prompt shows, and an unlabelled key prints as `(no comment -- unidentified
key)`.

## Getting in from another machine

On the machine I want to connect **from**:

```bash
cat ~/.ssh/id_ed25519.pub      # ssh-keygen -t ed25519 first if it has none
```

I cannot SSH in yet, so the line has to travel some other way -- it is a
public key, so no channel is too insecure. Over a tailnet, Taildrop avoids
copy-paste:

```bash
tailscale file cp ~/.ssh/id_ed25519.pub <this-machine>:   # from the other machine
tailscale file get ~/Downloads/                           # here
```

Append it to `ssh/authorized_keys` in this repo (with a trailing comment naming
the machine), then:

```bash
cd ~/dotfiles/ssh && ./install.sh
```

Confirm the key list at the prompt. The installer then generates host keys,
installs the hardened drop-in, and tries to switch the service on.

### Turn on Remote Login

This is a required step, and `install.sh` often cannot do it: `systemsetup`
needs the calling terminal to hold Full Disk Access. If the installer reports
it could not enable Remote Login, everything else is already in place and only
the switch is left:

**System Settings → General → Sharing → Remote Login → on**

(Or grant the terminal Full Disk Access and re-run, or use the `launchctl`
invocation in the quirks section below.) The drop-in is installed before this
point on purpose, so SSH is key-only the instant the service starts.

### Verify, then connect

```bash
sudo sshd -T | grep -iE 'passwordauthentication|kbdinteractive|permitrootlogin|allowusers'
```

Expect `no`, `no`, `no`, and an `allowusers` naming just my account.

To check the service is actually up, use a TCP connect rather than `lsof` --
launchd owns the socket as root, so an unprivileged `lsof` shows nothing even
when sshd is answering:

```bash
nc -z 127.0.0.1 22 && echo listening
```

Then, from the other machine (keep a session open here until it works):

```bash
ssh <me>@<this-machine>.<my-tailnet>.ts.net   # names from `tailscale status`
```

Undo at any point with `sudo systemsetup -setremotelogin off`, or the same
Sharing toggle.

### The lockout interlock

`install.sh` refuses to touch the server side while `ssh/authorized_keys` has no
keys in it. Enabling key-only SSH with zero authorized keys produces a running
server that nothing can authenticate to. Add a key first; the installer will
tell me so rather than half-configuring.

## Four macOS quirks worth knowing

**`ListenAddress` does nothing here.** macOS runs sshd under launchd *socket
activation*: `/System/Library/LaunchDaemons/ssh.plist` owns the listening
socket and spawns `sshd -i` per connection. sshd never binds a socket itself,
so `ListenAddress` in any config file is silently ignored. sshd cannot be pinned
to the tailnet interface this way, which is why the drop-in does not try.

**Drop-in ordering is backwards from what you'd guess.** OpenSSH keeps the
*first* value it obtains for a keyword, so a drop-in must sort *before*
`100-macos.conf` to override it. Hence `010-dotfiles.conf`.

**Host keys do not exist until Remote Login is first enabled.** macOS generates
`/etc/ssh/ssh_host_*` lazily, via `sshd-keygen-wrapper`, the first time launchd
starts sshd. Since `install.sh` validates the config with `sshd -t` *before*
enabling Remote Login, and `sshd -t` aborts with `no hostkeys available --
exiting` when they are missing, the installer runs `ssh-keygen -A` first.

The order is deliberate: host keys, then drop-in, then validate, then enable.
Enabling Remote Login first would also create the host keys, but would briefly
run sshd with password authentication still allowed.

**Turning Remote Login on needs Full Disk Access.** `systemsetup
-setremotelogin on` fails with *"requires Full Disk Access privileges"* unless
the calling terminal holds that permission — and it still exits 0 while doing
so, so `install.sh` verifies by checking for a listening socket rather than
trusting the exit code. If it cannot enable the service it says so and stops,
leaving everything else installed. Flip it on by any of:

- **System Settings → General → Sharing → Remote Login** (one toggle, no
  permission grant needed)
- Give the terminal Full Disk Access under **Privacy & Security**, then re-run
- `sudo launchctl enable system/com.openssh.sshd && sudo launchctl bootstrap
  system /System/Library/LaunchDaemons/ssh.plist`

Order still holds: the hardened drop-in is already in place by then, so SSH is
key-only from the instant the service comes up.

## Limiting exposure

Key-only auth (`PasswordAuthentication no`, `AuthenticationMethods publickey`)
means port 22 cannot be brute-forced — that is the load-bearing control here.
Beyond that:

- **Default posture:** with no port-22 forward on my router, this machine is
  reachable only from the LAN and the tailnet. That is usually enough.
- **Stricter:** to answer *only* on the Tailscale interface, that has to be a
  packet-filter rule, since `ListenAddress` is unavailable. Sketch:

  ```
  # /etc/pf.anchors/dotfiles.ssh
  block in proto tcp to any port 22
  pass in on utun3 proto tcp to any port 22
  ```

  The `utun` number is not stable across reboots, which is the main reason this
  is documented rather than installed by default.

## The drop-in is copied, not symlinked

Every other module in this repo symlinks. This one copies
`sshd_config.d/010-dotfiles.conf` to `/etc/ssh/sshd_config.d/` as root, because
sshd reads that file as root — a symlink into a user-writable repo would mean
anyone who can write `~/dotfiles` can rewrite the SSH server's config. Edit the
copy in this repo and re-run `install.sh`; edits made directly in `/etc` are
overwritten.

`install.sh` validates with `sshd -t` after installing and rolls back to the
previous drop-in if the merged config is invalid.
