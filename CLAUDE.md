# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a custom powerline-style statusline script for Claude Code. The script (`statusline-command.sh`) receives JSON input from Claude Code via stdin and outputs a formatted statusline with segments for directory, git info, model, context usage, cost, and timing.

## Commands

**Run tests:**
```bash
bats tests/statusline.bats
```

**Run a single test:**
```bash
bats tests/statusline.bats -f "test name pattern"
```

**Test script manually:**
```bash
echo '{"model": {"display_name": "Opus 4.5"}, "context_window": {"current_usage": {"input_tokens": 50000}, "context_window_size": 200000}}' | ./statusline-command.sh
```

## Architecture

The script works in three phases:
1. **JSON parsing** - Single `jq` call extracts all needed values from stdin
2. **Segment building** - `add_segment()` accumulates content with color codes
3. **Rendering** - `render_segments()` outputs ANSI-colored powerline format

Key functions:
- `dir_emoji()` - Generates deterministic emoji from directory path hash
- `build_progress_bar()` - Creates `█░` style progress bar from percentage
- `add_segment(content, bg, chevron_fg, text_fg)` - Queues a colored segment
- `render_segments()` - Outputs all segments with powerline chevrons

## Important Notes

- The chevron separator (U+E0B0) must be stored as raw UTF-8 bytes in the file, not as escape sequences like `$'\ue0b0'`
- Requires Powerline-compatible font (e.g., Nerd Fonts)
- Optional `claude-statusbar` integration for cost/timer data
