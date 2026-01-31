#!/bin/bash
# ==============================================================================
# Claude Code Custom Statusline Script - Powerline Style
# ==============================================================================

set -eo pipefail

# Powerline chevron separator (U+E0B0)
SEP=""

# Emojis for directory hashing (visually distinct set)
EMOJIS=(🔵 🟢 🟡 🟠 🔴 🟣 ⚪ 🔷 🔶 💎 🌟 ⭐ 🌙 🌈 🔥 💧 🌿 🍀 🌸 🎯 🎨 🎭 🎪 🚀 ✨ 💫 🌀 🎲 🎮 📦 🔮 💜 💙 💚 💛 🧡 ❤️ 🤍 🖤 🤎)

# Get emoji from directory hash
dir_emoji() {
    local dir="$1"
    local hash
    # macOS uses md5, Linux uses md5sum
    if command -v md5sum &>/dev/null; then
        hash=$(echo -n "$dir" | md5sum | cut -c1-8)
    else
        hash=$(echo -n "$dir" | md5 -q | cut -c1-8)
    fi
    local idx=$((16#$hash % ${#EMOJIS[@]}))
    echo "${EMOJIS[$idx]}"
}

# Segment storage: each entry is "content|bg|chevron_fg|text_fg"
segments=()
segments_plain=()

add_segment() {
    local content="$1" bg="$2" chevron_fg="$3" text_fg="$4"
    segments+=("$content|$bg|$chevron_fg|$text_fg")
    segments_plain+=("$content")
}

build_progress_bar() {
    local pct="$1"
    local filled=$((pct / 10))
    local empty=$((10 - filled))
    local bar=""
    [[ $filled -gt 0 ]] && bar=$(printf '█%.0s' $(seq 1 "$filled"))
    [[ $empty -gt 0 ]] && bar+=$(printf '░%.0s' $(seq 1 "$empty"))
    echo "$bar"
}

render_segments() {
    local output="" prev_chevron_fg=""
    local num=${#segments[@]}

    for ((i = 0; i < num; i++)); do
        IFS='|' read -r content bg chevron_fg text_fg <<< "${segments[$i]}"

        if [[ $i -eq 0 ]]; then
            output+="\033[${bg};${text_fg}m ${content} \033[0m"
        else
            output+="\033[${prev_chevron_fg};${bg}m${SEP}\033[0m"
            output+="\033[${bg};${text_fg}m ${content} \033[0m"
        fi
        prev_chevron_fg="$chevron_fg"
    done

    # Final chevron
    if [[ $num -gt 0 ]]; then
        output+="\033[${prev_chevron_fg}m${SEP}\033[0m"
    fi

    printf '%b' "$output"
}

# =============================================================================
# Main
# =============================================================================

input=$(cat)

# Extract all JSON values in one jq call
IFS=$'\t' read -r model current_tokens context_size remaining_pct < <(
    echo "$input" | jq -r '[
        (if .model | type == "object" then .model.display_name else .model end // "unknown"),
        ((.context_window.current_usage.input_tokens // 0) +
         (.context_window.current_usage.cache_creation_input_tokens // 0) +
         (.context_window.current_usage.cache_read_input_tokens // 0)),
        (.context_window.context_window_size // 0),
        (.context_window.remaining_percentage // "")
    ] | @tsv'
)

# Get directory info
dir_name=$(basename "$PWD")
emoji=$(dir_emoji "$PWD")

# Get git info (single status check)
git_branch="" git_dirty="" git_adds="" git_dels=""
if git rev-parse --git-dir &>/dev/null; then
    git_branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null) ||
        git_branch=$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null) || true

    if [[ -n "$git_branch" ]]; then
        # Single diff call for both dirty check and stats
        diff_output=$(git --no-optional-locks diff --numstat 2>/dev/null) || true
        cached_output=$(git --no-optional-locks diff --cached --numstat 2>/dev/null) || true

        if [[ -n "$diff_output" || -n "$cached_output" ]]; then
            git_dirty="✗ "
            read -r git_adds git_dels < <(
                echo "$diff_output" | awk '{a+=$1; d+=$2} END {print a+0, d+0}'
            )
        fi
    fi
fi

# Get claude-statusbar data (single call)
cost="" timer="" extra_usage=""
if command -v claude-statusbar &>/dev/null; then
    if statusbar_json=$(echo '{}' | claude-statusbar --json-output 2>/dev/null); then
        IFS=$'\t' read -r cost_raw timer source total_tokens token_limit < <(
            echo "$statusbar_json" | jq -r '[
                (.usage.cost_usd // ""),
                (.meta.reset_time // ""),
                (.usage.source // ""),
                (.usage.total_tokens // 0),
                (.usage.token_limit // 999999)
            ] | @tsv'
        )

        [[ -n "$cost_raw" && "$cost_raw" != "null" ]] && cost=$(printf '$%.2f' "$cost_raw")
        [[ -n "$timer" && "$timer" != "null" ]] && : || timer=""

        if [[ "$total_tokens" -gt "$token_limit" ]] 2>/dev/null ||
           [[ "$source" == "extra" || "$source" == "overflow" ]]; then
            extra_usage="EXTRA"
        fi
    fi
fi

# =============================================================================
# Build segments
# Colors: bg, chevron_fg, text_fg
# =============================================================================

# Segment 1: Directory with emoji + git branch (white bg, black text)
if [[ -n "$git_branch" ]]; then
    add_segment "${emoji} ${dir_name} on ${git_dirty}${git_branch}" "47" "37" "30"
else
    add_segment "${emoji} ${dir_name}" "47" "37" "30"
fi

# Segment 2: Git changes (red bg, bright white text)
if [[ -n "$git_adds" ]] && [[ "$git_adds" -gt 0 || "$git_dels" -gt 0 ]] 2>/dev/null; then
    add_segment "(+${git_adds},-${git_dels})" "41" "31" "97"
fi

# Segment 3: Model (pink/magenta bg, black text)
if [[ -n "$model" && "$model" != "unknown" ]]; then
    add_segment "$model" "45" "35" "30"
fi

# Segment 4: Context usage (color based on percentage)
if [[ "$context_size" -gt 0 ]] 2>/dev/null; then
    pct=$((current_tokens * 100 / context_size))
    bar=$(build_progress_bar "$pct")

    if [[ $pct -lt 60 ]]; then
        # Grey: 256-color mode
        add_segment "${pct}% [${bar}]" "48;5;240" "38;5;240" "97"
    elif [[ $pct -lt 80 ]]; then
        # Yellow
        add_segment "${pct}% [${bar}]" "43" "33" "30"
    else
        # Red
        add_segment "${pct}% [${bar}]" "41" "31" "97"
    fi
fi

# Segment 5: Cost (green bg, black text)
[[ -n "$cost" ]] && add_segment "$cost" "42" "32" "30"

# Segment 6: Extra usage indicator (red bg, bright white text)
[[ -n "$extra_usage" ]] && add_segment "$extra_usage" "41" "31" "97"

# =============================================================================
# Render output
# =============================================================================

left_output=$(render_segments)

# Build right side
right_side=""
[[ -n "$timer" ]] && right_side="resets in ${timer}"
if [[ -n "$remaining_pct" && "$remaining_pct" != "null" ]]; then
    remaining_int=$(printf '%.0f' "$remaining_pct" 2>/dev/null) || remaining_int=""
    if [[ -n "$remaining_int" ]]; then
        [[ -n "$right_side" ]] && right_side+=" | "
        right_side+="auto-compact in ${remaining_int}%"
    fi
fi

# Calculate padding and output
term_width=$(tput cols 2>/dev/null) || term_width=80
left_plain=" $(IFS=' '; echo "${segments_plain[*]}") ${SEP}"
left_len=${#left_plain}
right_len=${#right_side}
padding=$((term_width - left_len - right_len - 1))
[[ $padding -lt 1 ]] && padding=1

printf '%b%*s%s' "$left_output" "$padding" "" "$right_side"
