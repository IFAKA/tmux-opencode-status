#!/usr/bin/env bash

# Update each tmux window name with OpenCode state icon
# This script runs periodically and appends state icons to window names

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/opencode_sessions.sh"

# Get the base window name (without any existing state icon)
get_base_window_name() {
    local window_name="$1"
    # Remove any existing state icons (○●◉✗) from the end
    echo "$window_name" | sed -E 's/[○●◉✗]$//'
}

# Update window names with OpenCode states
update_window_names() {
    # Get all windows with their panes
    tmux list-windows -F "#{session_name}:#{window_index} #{window_name}" | while read -r window_info; do
        local window_target=$(echo "$window_info" | awk '{print $1}')
        local current_name=$(echo "$window_info" | cut -d' ' -f2-)
        local base_name=$(get_base_window_name "$current_name")
        
        # Get first pane in this window
        local pane_target=$(tmux list-panes -t "$window_target" -F "#{session_name}:#{window_index}.#{pane_index}" | head -1)
        
        # Check if this pane is running OpenCode
        local pane_command=$(tmux list-panes -t "$window_target" -F "#{pane_current_command}" | head -1)
        local pane_pid=$(tmux list-panes -t "$window_target" -F "#{pane_pid}" | head -1)
        
        local has_opencode=false
        
        # Check if it's an OpenCode process
        if echo "$pane_command" | grep -qiE "^(oc|opencode|node)$"; then
            if [ "$pane_command" = "node" ]; then
                if ps -p "$pane_pid" -o command= 2>/dev/null | grep -qiE "(opencode|oc)"; then
                    has_opencode=true
                fi
            else
                has_opencode=true
            fi
        fi
        
        if [ "$has_opencode" = true ]; then
            # Get state for this pane
            local state=$(detect_session_state "$pane_target")
            local icon=$(get_state_icon "$state")
            
            # Update window name with icon
            local new_name="${base_name}${icon}"
            
            # Only update if name changed
            if [ "$current_name" != "$new_name" ]; then
                tmux rename-window -t "$window_target" "$new_name"
            fi
        else
            # No OpenCode in this window - remove any existing icon
            if [ "$current_name" != "$base_name" ]; then
                tmux rename-window -t "$window_target" "$base_name"
            fi
        fi
    done
}

main() {
    update_window_names
}

main
