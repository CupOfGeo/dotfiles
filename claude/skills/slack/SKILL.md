---
name: slack
description: >-
  Interact with Slack from the terminal via the `slackcli` CLI — read messages
  and threads, search channels/people/messages, list conversations and unreads,
  read canvases and saved items, and send/react/edit/draft messages. Use this
  whenever the user wants to do anything in Slack: reading a Slack thread or
  permalink, searching Slack, checking unread channels, catching up on a
  conversation, posting or replying to a message, reacting, or drafting — even
  if they just paste a slack.com archive URL without saying "slackcli".
---

# slackcli — Slack from the terminal

`slackcli` (shaharia-lab/slackcli) is installed at `/opt/homebrew/bin/slackcli`.
Drive it via Bash. The default workspace is whatever `slackcli auth list` marks
as default (browser-token auth, so `messages draft` works and every action posts
**as the user**).

**Confirm before running anything that writes** (`messages send`/`react`/`edit`/`draft`).
It posts as the real user in a live workspace, which is hard to undo — show the
exact command and get an OK first. Reads are safe to run directly.

## Two things that will trip you up
- **Sub-subcommand help** only works as `slackcli <group> help <cmd>`
  (e.g. `slackcli messages help send`). Writing `slackcli messages send --help`
  silently prints the *top-level* help instead — confusing, but not an error.
- **`--permalink` is the shortcut everywhere.** Paste a Slack message link and it
  resolves the channel + thread-ts automatically — no need to extract IDs by hand.
  Most "read this thread" / "reply here" tasks start from a permalink.

Other conventions: add `--json` to any read command for raw timestamps /
scriptable output; timestamps accept `1234567890.123456` or `p1234567890123456`;
`--workspace <id|name>` targets a non-default workspace on any command.

## Reading (safe, no side effects)

```bash
# Read a message + its whole thread from a permalink (the common case)
slackcli conversations read --permalink "<slack-message-url>"

# Read a channel's history (by ID or URL)
slackcli conversations read <channel-id> [--limit 100] [--exclude-replies] \
  [--oldest <ts>] [--latest <ts>] [--json]

# Read a specific thread explicitly
slackcli conversations read <channel-id> --thread-ts <ts>

# One specific message
slackcli conversations get --permalink "<slack-message-url>"
slackcli conversations get <channel-id> <ts>

# List channels/DMs/groups
slackcli conversations list [--types public_channel,private_channel,mpim,im] \
  [--limit 100] [--exclude-archived] [--cursor <cursor>]

# Channels with unread messages
slackcli conversations unread [--types channels,dms,groups]
```

## Search

```bash
slackcli search messages "<query>" [--in <channel>] [--from <user>] \
  [--limit 20] [--sort score|timestamp] [--sort-dir asc|desc] [--json]
slackcli search channels "<query>" [--limit 20]
slackcli search people   "<name|email>" [--limit 20]
```

`search messages` supports standard Slack operators inside the query, e.g.
`in:#channel`, `from:@user`, `before:2026-08-01`, `after:`, `on:`, `has:link`.

## Attachments / downloading files (images, screenshots)

`slackcli` has **no file/download command** — a `conversations read` only prints
attachment *metadata* (filename, size, type, and a `files.slack.com/files-pri/...`
URL). That URL is auth-gated: an unauthenticated fetch 302-redirects to the login
page. But for a workspace signed in with **browser session tokens**, the same `xoxd`
token authenticates file downloads — so you *can* pull the actual bytes with curl.

**The fix for a "bounced" (302-to-login) download:** send the `xoxd` token as the
`d` cookie, but it **must be URL-encoded** — the raw token contains characters
(e.g. `/`, `+`, `=`) that silently break the cookie otherwise. Also follow
redirects (`-L`) and send a browser User-Agent. Plain `-b "d=<raw-xoxd>"` is the
usual reason a download bounces.

```bash
# Download a files-pri attachment to a local file, then Read it to view it.
python3 - "$FILE_URL" "$OUT_PATH" <<'PY'
import json, os, sys, urllib.parse, subprocess
url, out = sys.argv[1], sys.argv[2]
w = json.load(open(os.path.expanduser(
    '~/.config/slackcli/workspaces.json')))['workspaces']
w = w[next(iter(w))]  # or index by your workspace's name
cookie = 'd=' + urllib.parse.quote(w['xoxd_token'], safe='')  # URL-encode!
ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/126'
subprocess.run(['curl', '-sL', '-A', ua, '-b', cookie, url, '-o', out], check=True)
PY
file "$OUT_PATH"   # confirm it's a PNG/JPEG, not a 139-byte HTML redirect
```

Tokens live in `~/.config/slackcli/workspaces.json` (`xoxd_token`, `xoxc_token`).
Read them programmatically — never echo a token to stdout. These are the user's
own Slack session credentials; only ever send them to `files.slack.com` to fetch
their own accessible files, never to any other host.

If curl still bounces (expired/rotated token), fall back to the **interceptor**
browser surface, which uses the live signed-in browser session.

## Canvas / Saved

```bash
slackcli canvas list [--channel <id>] [--limit 20]
slackcli canvas read <canvas-id|url> [--raw] [--channel <id>]
slackcli saved list [--state saved|to_do|completed] [--limit <n>]
```

## Writing (side effects — CONFIRM FIRST)

```bash
# Send a message (to channel or user)
slackcli messages send --recipient-id <id|url> --message "<text>" [--file <path>]

# Reply in a thread
slackcli messages send --permalink "<message-url>" --message "<text>"
slackcli messages send --recipient-id <id> --thread-ts <ts> --message "<text>"

# React to a message
slackcli messages react --permalink "<message-url>" --emoji thumbsup

# Edit your own message
slackcli messages edit --permalink "<message-url>" --message "<new text>"

# Draft (browser-token only; does not send)
slackcli messages draft --recipient-id <id|url> --message "<text>"
```

## Auth / workspaces

```bash
slackcli auth list                     # show authenticated workspaces
slackcli auth set-default <workspace>
slackcli auth login-auto               # sign in via browser, captures tokens
```
