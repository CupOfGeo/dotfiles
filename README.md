# dotfiles

Personal config + setup scripts, organized as independent modules.

## Install on a fresh machine

> **The repo must live at `~/dotfiles`.** Several files (notably `zsh/zshrc`
> and the `claude/media-hook.sh` source line it appends) reference this
> absolute path. Cloning anywhere else will leave broken sources.

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

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
- `tmux/` — tmux config + Brewfile (`brew "tmux"`); installs TPM
- `zsh/` — zshrc + powerlevel10k config + aliases; installs oh-my-zsh, p10k, zsh-autosuggestions
- `nvim/` — NvChad-based neovim config (lazy.nvim self-bootstraps)
- `python/` — uv config + Python versions to install
- `npm/` — `.npmrc` (nvm itself is bootstrapped by the top-level installer)
- `iterm/` — iTerm2 prefs + Brewfile (cask `iterm2`, Meslo Nerd Font); install.sh points iTerm at this folder
- `vscode/` — settings, keybindings, and an `extensions.txt` list installed via the `code` CLI (macOS only)
- `claude/` — Claude Code global config + Brewfile (`rtk`, `nowplaying-cli`). The `enabledPlugins` list in `settings.json` only toggles plugins on — re-register each marketplace with `/plugin marketplace add ...` inside Claude Code on a fresh machine before they activate.

## Adding a new module

1. Create `<name>/` with the config files.
2. Add `<name>/install.sh` following the same pattern as the existing modules: source `lib/common.sh`, call `brew_bundle_if_present` if needed, use `link` for symlinks. `chmod +x` it.
3. If it has brew dependencies, add `<name>/Brewfile`.
4. Register `<name>` in the `ALL_MODULES` array near the top of the root `install.sh`.

## Cross-module note

`zsh/zshrc` sources `claude/media-hook.sh` (soft-guarded — degrades silently if absent). The function lives in `claude/` because it manages the `~/.claude/no-media` sentinel that the Claude Code hooks check. The file just needs to be present in the repo; no install step is required to satisfy this.

## Secrets

Secrets never live in this repo. The `.zshrc` sources `~/scripts/.secrets`, which lives outside dotfiles and is not tracked here.
