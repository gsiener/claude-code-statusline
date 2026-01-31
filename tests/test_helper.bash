# Test helper for statusline tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/statusline-command.sh"

# Sample JSON fixtures
fixture_minimal() {
    echo '{}'
}

fixture_basic() {
    cat <<'EOF'
{
    "model": {"display_name": "Opus 4.5"},
    "context_window": {
        "current_usage": {
            "input_tokens": 50000,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0
        },
        "context_window_size": 200000,
        "remaining_percentage": 75.0
    }
}
EOF
}

fixture_high_context() {
    cat <<'EOF'
{
    "model": {"display_name": "Sonnet 4"},
    "context_window": {
        "current_usage": {
            "input_tokens": 170000,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0
        },
        "context_window_size": 200000,
        "remaining_percentage": 15.0
    }
}
EOF
}

fixture_medium_context() {
    cat <<'EOF'
{
    "model": {"display_name": "Haiku 3.5"},
    "context_window": {
        "current_usage": {
            "input_tokens": 140000
        },
        "context_window_size": 200000,
        "remaining_percentage": 30.0
    }
}
EOF
}

fixture_model_string() {
    cat <<'EOF'
{
    "model": "claude-3-opus-20240229",
    "context_window": {
        "current_usage": {"input_tokens": 1000},
        "context_window_size": 200000
    }
}
EOF
}

# Strip ANSI codes for easier testing
strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g' | sed 's/\\033\[[0-9;]*m//g'
}

# Run script with fixture
run_with_fixture() {
    local fixture="$1"
    echo "$fixture" | "$SCRIPT" 2>&1
}
