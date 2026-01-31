#!/usr/bin/env bats

load test_helper

# =============================================================================
# Basic functionality tests
# =============================================================================

@test "script executes without error with minimal input" {
    run bash -c 'echo "{}" | '"$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "script executes without error with basic input" {
    result=$(fixture_basic | "$SCRIPT" 2>&1)
    [ -n "$result" ]
}

@test "outputs model name from display_name" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"Opus 4.5"* ]]
}

@test "outputs model name from string fallback" {
    result=$(fixture_model_string | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"claude-3-opus"* ]]
}

# =============================================================================
# Directory and emoji tests
# =============================================================================

@test "includes directory name in output" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    dir_name=$(basename "$PWD")
    [[ "$result" == *"$dir_name"* ]]
}

@test "directory emoji is consistent for same path" {
    result1=$(fixture_basic | "$SCRIPT" | strip_ansi)
    result2=$(fixture_basic | "$SCRIPT" | strip_ansi)
    # Both runs should produce identical output
    [ "$result1" = "$result2" ]
}

# =============================================================================
# Context percentage tests
# =============================================================================

@test "shows progress bar for context usage" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    # Should contain percentage and progress bar characters
    [[ "$result" == *"%"* ]]
    [[ "$result" == *"["* ]]
}

@test "calculates correct percentage (25% for 50k/200k)" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"25%"* ]]
}

@test "calculates correct percentage for high usage (85%)" {
    result=$(fixture_high_context | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"85%"* ]]
}

@test "calculates correct percentage for medium usage (70%)" {
    result=$(fixture_medium_context | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"70%"* ]]
}

# =============================================================================
# Right side content tests
# =============================================================================

@test "shows auto-compact percentage on right side" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"auto-compact in"* ]]
}

@test "shows correct remaining percentage" {
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    [[ "$result" == *"75%"* ]]
}

# =============================================================================
# Edge cases
# =============================================================================

@test "handles empty context_window gracefully" {
    result=$(echo '{"model": {"display_name": "test"}}' | "$SCRIPT" 2>&1 | strip_ansi)
    [ -n "$result" ]
    [[ "$result" == *"test"* ]]
}

@test "handles missing model gracefully" {
    result=$(echo '{"context_window": {"current_usage": {"input_tokens": 100}, "context_window_size": 1000}}' | "$SCRIPT" | strip_ansi)
    [ -n "$result" ]
}

@test "handles zero context size without division error" {
    run bash -c 'echo "{\"context_window\": {\"context_window_size\": 0}}" | '"$SCRIPT"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Git integration tests (only run in git repo)
# =============================================================================

@test "shows git branch when in git repo" {
    if ! git rev-parse --git-dir &>/dev/null; then
        skip "Not in a git repository"
    fi
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
    [[ "$result" == *"$branch"* ]]
}

@test "shows 'on' keyword with git branch" {
    if ! git rev-parse --git-dir &>/dev/null; then
        skip "Not in a git repository"
    fi
    result=$(fixture_basic | "$SCRIPT" | strip_ansi)
    [[ "$result" == *" on "* ]]
}

# =============================================================================
# Performance sanity check
# =============================================================================

@test "completes in reasonable time" {
    # Use seconds since millisecond timing varies by platform
    start=$(date +%s)
    for i in 1 2 3; do
        fixture_basic | "$SCRIPT" > /dev/null 2>&1
    done
    end=$(date +%s)
    duration=$((end - start))
    # 3 runs should complete in under 10 seconds
    [ "$duration" -lt 10 ]
}
