# iTerm2: auto-assign a tab color per tab, cycling a palette.
#
# Zero-cost: derives the color from the tab index that iTerm2 already
# exports in $ITERM_SESSION_ID (format "w<win>t<tab>p<pane>:UUID"), so
# there's no state file, counter, lock, or subprocess. The color is set
# synchronously as the shell inits, so a new tab is colored instantly.
#
# Deterministic-by-position: tab N always gets palette[N % len]. Closing
# a tab does not free its color for reuse (that would need the iTerm2
# Python API); this trades exact reclaim for near-zero latency.

# Only in an interactive iTerm2 session that gave us a session id.
if [[ -o interactive && "$TERM_PROGRAM" == "iTerm.app" && -n "$ITERM_SESSION_ID" ]]; then
  # Palette: "R G B" triples, 0-255. Edit/extend freely.
  local -a _iterm_palette=(
    "232 122 122"   # red
    "232 168 106"   # orange
    "214 200 106"   # yellow
    "138 200 128"   # green
    "106 190 214"   # cyan
    "120 156 232"   # blue
    "176 138 224"   # purple
    "224 138 194"   # pink
  )

  # Extract the tab number: strip up to "t", then everything from "p" on.
  local _iterm_tab="${ITERM_SESSION_ID#*t}"
  _iterm_tab="${_iterm_tab%%p*}"

  # Guard against a non-numeric id; default to tab 0.
  [[ "$_iterm_tab" == <-> ]] || _iterm_tab=0

  local _iterm_idx=$(( _iterm_tab % ${#_iterm_palette[@]} + 1 ))  # zsh arrays are 1-based
  local _iterm_rgb=(${=_iterm_palette[$_iterm_idx]})

  printf '\033]6;1;bg;red;brightness;%d\a'   "${_iterm_rgb[1]}"
  printf '\033]6;1;bg;green;brightness;%d\a' "${_iterm_rgb[2]}"
  printf '\033]6;1;bg;blue;brightness;%d\a'  "${_iterm_rgb[3]}"

  unset _iterm_palette _iterm_tab _iterm_idx _iterm_rgb
fi
