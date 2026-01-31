#!/bin/bash
# ==============================================================================
# Claude Code Custom Statusline Script - Powerline Style
# ==============================================================================

# Read JSON input from stdin
input=$(cat)

# Powerline chevron separator (U+E0B0)
SEP=$(printf '\xee\x82\xb0')

# Background colors
BG_GREEN=42
BG_YELLOW=43
BG_RED=41
BG_PINK=45
BG_GREY="48;5;240"
BG_WHITE=47

# Foreground colors (for chevrons - must match bg colors)
FG_GREEN=32
FG_YELLOW=33
FG_RED=31
FG_PINK=35
FG_BLACK=30
FG_WHITE=37
FG_WHITE_BRIGHT=97
FG_GREY="38;5;240"

# Extract model name
model=$(echo "$input" | jq -r '.model.display_name // .model // "unknown"')

# Get context usage percentage, build progress bar, and determine color
ctx_content=""
ctx_bg=$BG_GREY
ctx_fg=$FG_GREY
ctx_text_color=$FG_WHITE_BRIGHT
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ] && [ "$usage" != "" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    if [ "$size" != "null" ] && [ "$size" != "0" ] && [ -n "$size" ]; then
        pct=$((current * 100 / size))

        # Build progress bar with percentage in front
        filled=$((pct / 10))
        empty=$((10 - filled))
        bar=""
        for ((j=0; j<filled; j++)); do
            bar="${bar}█"
        done
        for ((j=0; j<empty; j++)); do
            bar="${bar}░"
        done
        ctx_content="${pct}% [${bar}]"

        # Color based on percentage
        if [ $pct -lt 60 ]; then
            ctx_bg=$BG_GREY
            ctx_fg=$FG_GREY
            ctx_text_color=$FG_WHITE_BRIGHT
        elif [ $pct -lt 80 ]; then
            ctx_bg=$BG_YELLOW
            ctx_fg=$FG_YELLOW
            ctx_text_color=$FG_BLACK
        else
            ctx_bg=$BG_RED
            ctx_fg=$FG_RED
            ctx_text_color=$FG_WHITE_BRIGHT
        fi
    fi
fi

# Get data from claude-statusbar (JSON)
cost=""
timer=""
extra_usage=""
if command -v claude-statusbar &>/dev/null; then
    statusbar_json=$(echo '{}' | claude-statusbar --json-output 2>/dev/null)
    if [ -n "$statusbar_json" ]; then
        # Extract cost
        cost_raw=$(echo "$statusbar_json" | jq -r '.usage.cost_usd // empty')
        if [ -n "$cost_raw" ] && [ "$cost_raw" != "null" ]; then
            cost=$(printf '$%.2f' "$cost_raw")
        fi

        # Extract timer
        timer=$(echo "$statusbar_json" | jq -r '.meta.reset_time // empty')

        # Check for extra usage (when tokens exceed limit)
        total_tokens=$(echo "$statusbar_json" | jq -r '.usage.total_tokens // 0')
        token_limit=$(echo "$statusbar_json" | jq -r '.usage.token_limit // 999999')
        if [ "$total_tokens" -gt "$token_limit" ] 2>/dev/null; then
            extra_usage="EXTRA"
        fi

        # Also check source field for extra usage indicator
        source=$(echo "$statusbar_json" | jq -r '.usage.source // empty')
        if [ "$source" = "extra" ] || [ "$source" = "overflow" ]; then
            extra_usage="EXTRA"
        fi
    fi
fi

# Get git info
git_branch=""
git_dirty=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch="$branch"
        if ! git --no-optional-locks diff --quiet 2>/dev/null || ! git --no-optional-locks diff --cached --quiet 2>/dev/null; then
            git_dirty="✗ "
        fi
    fi
fi

# Get git line changes
git_changes=""
if [ -n "$git_branch" ]; then
    if ! git --no-optional-locks diff --quiet 2>/dev/null || ! git --no-optional-locks diff --cached --quiet 2>/dev/null; then
        stats=$(git --no-optional-locks diff --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print add","del}')
        adds=$(echo "$stats" | cut -d',' -f1)
        dels=$(echo "$stats" | cut -d',' -f2)
        if [ -n "$adds" ] && [ -n "$dels" ] && [ "$adds" != "" ] && [ "$dels" != "" ]; then
            git_changes="(+${adds},-${dels})"
        fi
    fi
fi

# Get remaining context percentage
remaining_pct=""
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$remaining" ]; then
    remaining_pct=$(printf "%.0f" "$remaining")
fi

# Build segments array: "content|bg_color|fg_for_chevron|text_color"
segments=()
plain_segments=()

# Segment 1: Git branch (White bg, black text)
if [ -n "$git_branch" ]; then
    segments+=("${git_dirty}${git_branch}|${BG_WHITE}|${FG_WHITE}|${FG_BLACK}")
    plain_segments+=("${git_dirty}${git_branch}")
fi

# Segment 2: Git changes (Red)
if [ -n "$git_changes" ]; then
    segments+=("${git_changes}|${BG_RED}|${FG_RED}|${FG_WHITE_BRIGHT}")
    plain_segments+=("${git_changes}")
fi

# Segment 3: Model (Purple)
if [ -n "$model" ] && [ "$model" != "unknown" ]; then
    segments+=("${model}|${BG_PINK}|${FG_PINK}|${FG_BLACK}")
    plain_segments+=("${model}")
fi

# Segment 4: Context usage (dynamic color with progress bar)
if [ -n "$ctx_content" ]; then
    segments+=("${ctx_content}|${ctx_bg}|${ctx_fg}|${ctx_text_color}")
    plain_segments+=("${ctx_content}")
fi

# Segment 5: Cost (Green)
if [ -n "$cost" ]; then
    segments+=("${cost}|${BG_GREEN}|${FG_GREEN}|${FG_BLACK}")
    plain_segments+=("${cost}")
fi

# Segment 6: Extra usage indicator (Red, if active)
if [ -n "$extra_usage" ]; then
    segments+=("${extra_usage}|${BG_RED}|${FG_RED}|${FG_WHITE_BRIGHT}")
    plain_segments+=("${extra_usage}")
fi

# Render the powerline
output=""
output_plain=""
num_segments=${#segments[@]}

for ((i=0; i<num_segments; i++)); do
    IFS='|' read -r content bg chevron_fg text_color <<< "${segments[$i]}"

    if [ $i -eq 0 ]; then
        # First segment: just the content
        output=$(printf '\033[%s;%sm %s \033[0m' "$bg" "$text_color" "$content")
    else
        # Get previous segment's chevron color
        IFS='|' read -r _ prev_bg prev_chevron_fg _ <<< "${segments[$((i-1))]}"
        # Chevron: previous bg color as foreground, current bg as background
        output=$(printf '%s\033[%s;%sm%s\033[0m' "$output" "$prev_chevron_fg" "$bg" "$SEP")
        # Content
        output=$(printf '%s\033[%s;%sm %s \033[0m' "$output" "$bg" "$text_color" "$content")
    fi

    output_plain="${output_plain} ${content} "
done

# Final chevron (to default background)
if [ $num_segments -gt 0 ]; then
    IFS='|' read -r _ _ last_chevron_fg _ <<< "${segments[$((num_segments-1))]}"
    output=$(printf '%s\033[%sm%s\033[0m' "$output" "$last_chevron_fg" "$SEP")
    output_plain="${output_plain}${SEP}"
fi

# Right side: Timer and context remaining
right_side=""
right_side_plain=""
if [ -n "$timer" ] && [ -n "$remaining_pct" ]; then
    right_side="resets in ${timer} | auto-compact in ${remaining_pct}%"
elif [ -n "$timer" ]; then
    right_side="resets in ${timer}"
elif [ -n "$remaining_pct" ]; then
    right_side="auto-compact in ${remaining_pct}%"
fi
right_side_plain="$right_side"

# Calculate padding for right alignment
term_width=$(tput cols 2>/dev/null || echo 80)
left_len=${#output_plain}
right_len=${#right_side_plain}
padding=$((term_width - left_len - right_len - 1))
if [ $padding -lt 1 ]; then
    padding=1
fi

# Output the complete statusline
printf '%s%*s%s' "$output" "$padding" "" "$right_side"
