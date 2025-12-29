#!/usr/bin/env bash

# Get color for a specific window based on OpenCode state
# Usage: get_window_color.sh <window_index>

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/opencode_sessions.sh"

window_index="$1"

# Get the window's pane
pane_target=$(tmux list-panes -t ":${window_index}" -F "#{session_name}:#{window_index}.#{pane_index}" | head -1)

if [ -z "$pane_target" ]; then
    echo "default"
    exit 0
fi

# Check if running OpenCode
pane_command=$(tmux list-panes -t ":${window_index}" -F "#{pane_current_command}" | head -1)
pane_pid=$(tmux list-panes -t ":${window_index}" -F "#{pane_pid}" | head -1)

has_opencode=false

if echo "$pane_command" | grep -qiE "^(oc|opencode|node)$"; then
    if [ "$pane_command" = "node" ]; then
        if ps -p "$pane_pid" -o command= 2>/dev/null | grep -qiE "(opencode|oc)"; then
            has_opencode=true
        fi
    else
        has_opencode=true
    fi
fi

if [ "$has_opencode" = false ]; then
    echo "default"
    exit 0
fi

# Get state and color
state=$(detect_session_state "$pane_target")
color=$(get_state_color "$state")

echo "$color"
