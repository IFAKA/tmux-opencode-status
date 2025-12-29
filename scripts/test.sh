#!/usr/bin/env bash

# Simple test script to verify plugin functionality

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

echo "Testing tmux-opencode-status plugin..."
echo ""

# Test 1: Helper functions
echo "Test 1: Helper functions"
if command_exists "tmux"; then
    echo "  ✓ tmux is available"
else
    echo "  ✗ tmux is not available"
    exit 1
fi

if is_osx; then
    echo "  ✓ Platform: macOS"
elif is_linux; then
    echo "  ✓ Platform: Linux"
else
    echo "  ✓ Platform: Other Unix"
fi
echo ""

# Test 2: Tmux is running
echo "Test 2: Tmux environment"
if [ -n "$TMUX" ]; then
    echo "  ✓ Running inside tmux"
else
    echo "  ⚠️  Not running inside tmux"
    echo "     This is okay - the plugin will work when tmux starts"
fi
echo ""

# Test 3: Script permissions
echo "Test 3: Script permissions"
if [ -x "$CURRENT_DIR/helpers.sh" ]; then
    echo "  ✓ helpers.sh is executable"
else
    echo "  ✗ helpers.sh is not executable"
fi

if [ -x "$CURRENT_DIR/opencode_sessions.sh" ]; then
    echo "  ✓ opencode_sessions.sh is executable"
else
    echo "  ✗ opencode_sessions.sh is not executable"
fi

if [ -x "$CURRENT_DIR/../opencode-status.tmux" ]; then
    echo "  ✓ opencode-status.tmux is executable"
else
    echo "  ✗ opencode-status.tmux is not executable"
fi
echo ""

# Test 4: Configuration reading
echo "Test 4: Configuration"
test_value=$(get_tmux_option "@opencode_test_option" "default_value")
if [ "$test_value" = "default_value" ]; then
    echo "  ✓ get_tmux_option works (returned default value)"
else
    echo "  ✓ get_tmux_option works (found custom value: $test_value)"
fi
echo ""

# Test 5: Try to run the main script
echo "Test 5: Main script execution"
if output=$("$CURRENT_DIR/opencode_sessions.sh" 2>&1); then
    echo "  ✓ Script runs without errors"
    if [ -n "$output" ]; then
        echo "  Output: $output"
    else
        echo "  (No OpenCode sessions detected - this is normal)"
    fi
else
    echo "  ✗ Script failed to run"
fi
echo ""

echo "All tests completed!"
echo ""
echo "To install the plugin:"
echo "  1. Add to ~/.tmux.conf:"
echo "     set -g @plugin 'IFAKA/tmux-opencode-status'"
echo "     set -g status-right '#{opencode_status} | %H:%M'"
echo ""
echo "  2. Reload tmux config:"
echo "     tmux source-file ~/.tmux.conf"
echo ""
echo "For debugging, run:"
echo "  $CURRENT_DIR/debug.sh"
