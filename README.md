# dotfiles

Personal config + setup scripts.

## Install on a fresh machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then open tmux and press `prefix + I` to fetch plugins via TPM.

## Layout

- `Brewfile` — system packages (tmux, pyenv, fonts, etc.)
- `install.sh` — bootstrap: brew, TPM, oh-my-zsh, p10k, nvm, symlinks
- `tmux/` — tmux config
- `zsh/`  — zshrc + powerlevel10k config
- `nvim/` — NvChad-based neovim config
- `python/` — uv config + Python versions to install
- `iterm/` — iTerm2 prefs (install.sh points iTerm at this folder; iTerm reads/writes the plist here)
- `vscode/` — settings, keybindings, and an `extensions.txt` list installed via the `code` CLI

## Adding a new tool

1. Drop its config into a new folder (e.g. `vim/vimrc`).
2. Add a `link ...` line in `install.sh`.
3. Add any packages it needs to the `Brewfile`.

## Secrets

Secrets never live in this repo. The `.zshrc` sources `~/scripts/.secrets`,
which lives outside dotfiles and is not tracked here.
