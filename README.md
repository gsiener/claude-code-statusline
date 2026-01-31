# Claude Code Custom Statusline

A powerline-style statusline for Claude Code displaying directory, git info, model, context usage, cost, and timing information.

## Screenshot

```
 🎨 my-project on ✗ main  (+5,-2)  Opus 4.5  13% [█░░░░░░░░░]  $40.09       resets in 25m | auto-compact in 87%
```

## Segments (left to right)

| Segment | Color | Description |
|---------|-------|-------------|
| Directory | White bg, black text | Unique emoji (hashed from path) + directory name + "on" + branch |
| Git changes | Red bg, white text | Lines added/deleted (+N,-N) |
| Model | Purple bg, black text | Current Claude model |
| Context | Grey/Yellow/Red bg | Usage percentage with progress bar |
| Cost | Green bg, black text | Session cost from claude-statusbar |
| Extra usage | Red bg, white text | Shows "EXTRA" when in extra usage mode |

**Right side:** `resets in Xm | auto-compact in X%`

## Directory Emoji

Each directory gets a unique emoji based on its full path hash. This makes it easy to visually identify which project you're in at a glance. The emoji is deterministic - the same directory always gets the same emoji.

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
    "command": "~/.claude/statusline-command.sh"
  }
}
```

## Dependencies

- `jq` - JSON parsing
- `git` - Repository info
- `md5sum` or `md5` - Directory emoji hashing (included on Linux/macOS)
- `claude-statusbar` (optional) - Cost and timer data

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

```bash
# Install bats (macOS)
brew install bats-core

# Install bats (Linux)
sudo apt install bats

# Run tests
bats tests/statusline.bats
```

## Font

Requires a Powerline-compatible font (e.g., Nerd Fonts) for chevron separators.
