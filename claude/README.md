# Claude code 

### context7
https://context7.com/ context7 is the only mcp tool I actually like. you use it to grab latest documentation tell calude to "use context 7". Great resarching in planing phase and context priming. 

### RTK
https://github.com/rtk-ai/rtk 

### LSP's 
I add the python and javascript language server protocol. go is commented out but you can uncomment.

### media-hooks.sh
the media-hooks.sh script is used with the settings.json with the claude hooks. Where if activated with `media-hooks on` while calude is thinking/working your current media will start to play and when claude stops to ask for user input / tool call your media will pause. This is a global hooks so they work on all calude sessions so if you are running multiple sessions they will interfear with play/pauseing the media.

When claude takes control media plays when gives control back to user media pauses so you can read and think. 

### zsh history hook
A `PostToolUse` hook on `Bash` in settings.json appends every command Claude runs to `~/.zsh_history`, so you can reuse them outside Claude (open shells pick them up via `share_history`, or run `fc -R`). It strips the `rtk ` prefix the RTK hook adds.

Known issue: RTK fully rewrites some commands (e.g. `tail -n 2 file` → `rtk read file --tail-lines 2`), and the hook only sees the rewritten version, so those land in history as `read file --tail-lines 2`. Fix if it gets annoying: skip them with `select(.tool_input.command | test("rtk read") | not) |` in the hook's jq.
