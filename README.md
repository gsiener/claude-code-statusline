# Claude Code Custom Statusline

A powerline-style statusline for Claude Code displaying git info, model, context usage, cost, and timing information.

## Screenshot

```
 ✗ main  (+5,-2)  Opus 4.5  13% [█░░░░░░░░░]  $40.09       resets in 25m | auto-compact in 87%
```

## Segments (left to right)

| Segment | Color | Description |
|---------|-------|-------------|
| Git branch | White bg, black text | Shows dirty indicator (✗) and branch name |
| Git changes | Red bg, white text | Lines added/deleted (+N,-N) |
| Model | Purple bg, black text | Current Claude model |
| Context | Grey/Yellow/Red bg | Usage percentage with progress bar |
| Cost | Green bg, black text | Session cost from claude-statusbar |
| Extra usage | Red bg, white text | Shows "EXTRA" when in extra usage mode |

**Right side:** `resets in Xm | auto-compact in X%`

## Context Colors

- **Grey**: < 60% usage
- **Yellow**: 60-80% usage
- **Red**: > 80% usage

## Setup

1. Save `statusline-command.sh` to `~/.claude/statusline-command.sh`
2. Make executable: `chmod +x ~/.claude/statusline-command.sh`
3. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/path/to/.claude/statusline-command.sh"
  }
}
```

## Dependencies

- `jq` - JSON parsing
- `git` - Repository info
- `claude-statusbar` (optional) - Cost and timer data

## Font

Requires a Powerline-compatible font (e.g., Nerd Fonts) for chevron separators.
