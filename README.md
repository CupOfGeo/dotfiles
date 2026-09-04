# dotfiles

My config + setup scripts, organized as independent modules.

## Install on a fresh machine

> **The repo must live at `~/dotfiles`.** Several files (notably `zsh/zshrc`
> and the `claude/media-hook.sh` source line it appends) reference this
> absolute path. Cloning anywhere else will leave broken sources.

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

> **Not me?** Change the git identity in `git/gitconfig` and clear
> `ssh/authorized_keys` before installing — see [Personal data](#personal-data).

Then open tmux and press `prefix + I` to fetch plugins via TPM.

## Usage

```bash
./install.sh                # install everything
./install.sh tmux zsh       # install only the named modules
./install.sh --list         # print available modules
./install.sh --help         # usage

cd <module> && ./install.sh # install a single module standalone
                            # (skips the shared brew + nvm bootstrap)
```

The top-level installer bootstraps shared prerequisites (Homebrew, nvm + Node LTS) and then runs each selected module's installer. Module installers are also runnable on their own — each one resolves the repo root from its own path and sources the shared lib.

## Layout

- `install.sh` — orchestrator: shared bootstrap (brew, nvm) + module iteration with optional subset args
- `lib/common.sh` — shared helpers (`link`, `ensure_brew`, logging) sourced by every module installer
- `git/` — global `.gitconfig` (identity, `init.defaultBranch`, `push.autoSetupRemote`, LFS filters) + Brewfile (`git-lfs`, required by the LFS filters)
- `ssh/` — client `~/.ssh/config` + SSH **server** setup so my other machines can SSH in over the tailnet (key-only auth, Remote Login, `sshd_config.d` drop-in copied root-owned). Public keys only; private keys never enter the repo. See `ssh/README.md`
- `apps/` — Brewfile of simple "just install it" tools (tailscale, brave, colima/docker, ack); registers colima as a login service
- `tmux/` — tmux config + Brewfile (`brew "tmux"`); installs TPM
- `zsh/` — zshrc + powerlevel10k config + aliases; installs oh-my-zsh, p10k, zsh-autosuggestions
- `nvim/` — NvChad-based neovim config (lazy.nvim self-bootstraps)
- `python/` — uv config + Python versions to install
- `npm/` — `.npmrc` (nvm itself is bootstrapped by the top-level installer)
- `iterm/` — iTerm2 prefs + Brewfile (cask `iterm2`, Meslo Nerd Font); install.sh points iTerm at this folder
- `vscode/` — Brewfile (cask `visual-studio-code`) + settings, keybindings, and an `extensions.txt` list installed via the `code` CLI (macOS only)
- `claude/` — Claude Code global config + Brewfile (`rtk`, `nowplaying-cli`). The `enabledPlugins` list in `settings.json` only toggles plugins on — re-register each marketplace with `/plugin marketplace add ...` inside Claude Code on a fresh machine before they activate.
- `interceptor/` — [Interceptor](https://github.com/Hacker-Valley-Media/Interceptor) CLI + daemon that drives a signed-in browser from the command line (browser-only install). Not in brew — `install.sh` downloads the pinned signed pkg, verifies checksum + notarization, `sudo installer`s it, and adopts its skill packs into `~/.claude/skills`. Loading the browser extension is a manual step (see the module README).

## Adding a new module

1. Create `<name>/` with the config files.
2. Add `<name>/install.sh` following the same pattern as the existing modules: source `lib/common.sh`, call `brew_bundle_if_present` if needed, use `link` for symlinks. `chmod +x` it.
3. If it has brew dependencies, add `<name>/Brewfile`.
4. Register `<name>` in the `ALL_MODULES` array near the top of the root `install.sh`.

## Cross-module note

`zsh/zshrc` sources `claude/media-hook.sh` (soft-guarded — degrades silently if absent). The function lives in `claude/` because it manages the `~/.claude/no-media` sentinel that the Claude Code hooks check. The file just needs to be present in the repo; no install step is required to satisfy this.

## Secrets

I keep secrets out of this repo entirely. My `.zshrc` sources `~/.secrets`, which lives outside dotfiles and isn't tracked here.

## Personal data

I set this repo up for myself, not as a neutral template. Two tracked files hold
my personal data, and if you're not me you'll want to change both before
installing:

| File | Holds | If you're not me |
| --- | --- | --- |
| `git/gitconfig` | my `user.name` / `user.email` | Edit the `[user]` block, or your commits get authored as me |
| `ssh/authorized_keys` | my machines' public keys | Clear it and add your own, or my keys get a login on your machine |

I track both on purpose — having them here is what makes a fresh machine work
immediately, which is the case I actually optimize for. But the two failure
modes aren't equally visible, so I guard them differently.

A wrong git identity announces itself: I'd spot it in `git log` and fix it with
`git commit --amend`. A wrong `authorized_keys` is silent, so `ssh/install.sh`
prints exactly whose keys it's about to authorize and waits for confirmation
before installing them. A README warning gets skimmed; a prompt shows up at the
moment it matters.

```bash
# If you're not me:
git config --file git/gitconfig user.name  "Your Name"
git config --file git/gitconfig user.email "you@example.com"
: > ssh/authorized_keys        # then add your own public keys
```

`~/.gitconfig` is a symlink to `git/gitconfig`, so `git config --global` writes
**through it into the tracked file** — an accidental `--global` write shows up as
a repo diff.

### Files kept outside the repo

| File | Holds | Created by |
| --- | --- | --- |
| `~/.secrets` | env vars, tokens — sourced by `.zshrc` | me, by hand |
| `~/.ssh/config.local` | my SSH host entries (tailnet, work, jump hosts) | `ssh/install.sh` |
| `~/.ssh/id_ed25519` | this machine's private key | `ssh/install.sh` |

`.gitignore` lists `id_ed25519` / `id_rsa` and friends explicitly: the older
`*_key*` / `*.key` / `*.pem` patterns do **not** match OpenSSH's default key
filenames, so a private key dropped in the repo would otherwise be committable.
