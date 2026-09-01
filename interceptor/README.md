# interceptor

[Interceptor](https://github.com/Hacker-Valley-Media/Interceptor) — a CLI +
background daemon that drives a **real, signed-in** browser session (Brave /
Chrome / Safari) from the command line, built for AI agents. This machine runs
the **browser-only** install.

## Why this is its own module (not part of `brave/`)

Every dependency points *out* of Brave:

- It's distributed as a signed macOS `.pkg`, not a browser thing.
- It drives Brave **or** Chrome **or** Safari — it doesn't need Brave specifically.
- It wires its skill packs into `~/.claude/skills` (the `skills adopt` step).

Brave, by contrast, needs nothing from Interceptor. So the coupling lives here,
inside the module that owns those links.

## What `install.sh` does

1. **Installs the pinned pkg** (`VERSION` at the top of the script) — downloads
   the signed release, verifies it against `SHA256SUMS`, checks the Apple
   signature + notarization (Team ID `TPWBZD35WW`, Hacker Valley Media, LLC),
   then `sudo installer`. Idempotent: skips if the pinned version is already
   present.
2. **Adopts the skill packs** into Claude Code (`interceptor skills adopt --into
   claude`) — symlinks the shipped playbooks so agents use the tool fluently.
3. **Prints the one manual step** it cannot automate (below).

Not in Homebrew, so there is no `Brewfile`. After the first install Interceptor
self-updates via Sparkle — bumping `VERSION` here only affects fresh machines.

## Manual step: load the browser extension

Brave/Chrome forbid programmatic unpacked-extension loads outside the Web Store,
so this stays by hand:

1. Open `brave://extensions/` (or `chrome://extensions/`)
2. Enable **Developer mode** (top-right)
3. Click **Load unpacked**
4. Select `/Library/Application Support/Interceptor/extension/`
   (in the file picker press **⌘⇧G** and paste that path — `/Library` is hidden)

Verify the whole chain:

```bash
interceptor open "https://example.com"
```

## Upgrading the pin

Edit `VERSION` in `install.sh` to the new release tag (without the leading `v`)
and confirm the pkg asset name still matches `PKG_NAME`.

## Adding native macOS / iPhone control

This is the browser-only install. To add native app + device control later:

```bash
interceptor upgrade --full
```
