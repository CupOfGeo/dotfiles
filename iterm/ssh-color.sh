# iTerm2: tint the window background while an ssh session is running.
#
# Wraps `ssh` in a function that sends iTerm's SetColors escape before the
# connection and restores the profile background when ssh exits (normally,
# by Ctrl-C, or by a dropped connection). Nothing is installed on the remote
# host and no shell integration is needed, because the color change happens
# in the local terminal around the ssh process.
#
# Works inside tmux: the escape is wrapped in a DCS passthrough envelope,
# which needs `set -g allow-passthrough on` in tmux.conf.
#
# Override colors per shell if you like (hex RGB, no '#'):
#   ITERM_SSH_BG    background while ssh is running   (default: dark green tint)
#   ITERM_LOCAL_BG  background to restore afterwards  (default: profile #1e1e1e)

# Only in an interactive shell that ultimately lives in iTerm2 (LC_TERMINAL
# survives tmux, TERM_PROGRAM does not).
if [[ -o interactive && ( "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ) ]]; then
  : "${ITERM_SSH_BG:=1a2a1e}"
  : "${ITERM_LOCAL_BG:=1e1e1e}"

  # Emit an iTerm proprietary escape, wrapped for tmux when needed.
  _iterm_set_bg() {
    local seq=$'\e]1337;SetColors=bg='"$1"$'\a'
    if [[ -n "$TMUX" ]]; then
      # DCS tmux; <sequence with every ESC doubled> ST
      local esc=$'\e'
      printf '\ePtmux;%s\e\\' "${seq//$esc/$esc$esc}"
    else
      printf '%s' "$seq"
    fi
  }

  ssh() {
    _iterm_set_bg "$ITERM_SSH_BG"
    {
      command ssh "$@"
    } always {
      _iterm_set_bg "$ITERM_LOCAL_BG"
    }
  }
fi
