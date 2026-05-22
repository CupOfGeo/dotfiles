media-hook() {
  local sentinel=~/.claude/no-media
  case "$1" in
    off)    touch "$sentinel" && echo "media hooks muted" ;;
    on)     rm -f "$sentinel" && echo "media hooks active" ;;
    toggle) if [ -f "$sentinel" ]; then media-hook on; else media-hook off; fi ;;
    "")     if [ -f "$sentinel" ]; then echo "muted"; else echo "active"; fi ;;
    *)      echo "usage: media-hook [on|off|toggle]" >&2; return 1 ;;
  esac
}
