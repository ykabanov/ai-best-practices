# Claude Code Statusline

A single-line statusline for [Claude Code](https://code.claude.com/docs) that shows, in order:

- current directory
- git branch + dirty-state indicator (`✗` if there are uncommitted changes)
- PR number and review state (`✓` approved, `✗` changes requested, `⋯` pending, `draft`)
- active model name
- reasoning effort level (if set)
- context window usage %, color-coded (green < 50%, yellow 50–79%, red ≥ 80%)
- session cost in USD (once it's non-zero)

Every field is optional and only renders when the corresponding data is present in the JSON Claude Code passes on stdin.

## Install

1. Copy `statusline-command.sh` somewhere on disk, e.g. `~/.claude/statusline-command.sh`, and make it executable:
   ```bash
   chmod +x ~/.claude/statusline-command.sh
   ```
2. Point Claude Code at it in `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline-command.sh"
     }
   }
   ```

Requires `jq` and `awk` (both standard on macOS/Linux).
