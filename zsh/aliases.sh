alias gs='git status'
alias mcp-inspector="npm update -g @modelcontextprotocol/inspector && npx @modelcontextprotocol/inspector"
# TrueNAS API via Caddy (HTTPS end to end since 2026-11-08; plain http hop revoked keys). Key from NAS_API_KEY in ~/.zshrc, expanded at call time.
alias tn='midclt -u wss://nas.mainbranch.net/api/current -K "$NAS_API_KEY"'
