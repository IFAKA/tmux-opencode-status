#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# State detection for OpenCode sessions
# States: idle, busy, waiting, error, loading
detect_session_state() {
    local pane_id="$1"
    local pane_content
    
    # Capture last 50 lines of pane content
    pane_content=$(tmux capture-pane -p -t "$pane_id" -S -50 2>/dev/null || echo "")
    
    # Check for various states (most specific first)
    
    # Error state - look for error messages
    if echo "$pane_content" | grep -qiE "(error|failed|exception|fatal)"; then
        echo "error"
        return
    fi
    
    # Waiting for input - look for common prompts
    if echo "$pane_content" | grep -qE "(y/n|yes/no|continue\?|proceed\?|\[Y/n\]|\(y/N\))"; then
        echo "waiting"
        return
    fi
    
    # Loading/processing - look for progress indicators
    if echo "$pane_content" | grep -qE "(loading|processing|running|executing|working|analyzing|searching)"; then
        echo "busy"
        return
    fi
    
    # Check if there's recent activity (OpenCode prompt visible)
    if echo "$pane_content" | grep -qE "(opencode|claude|assistant|>|$)"; then
        # Look for thinking/processing indicators
        if echo "$pane_content" | tail -5 | grep -qE "\.\.\."; then
            echo "busy"
            return
        fi
        echo "idle"
        return
    fi
    
    # Default to idle
    echo "idle"
}

# Find all panes running OpenCode
find_opencode_panes() {
    local panes=()
    
    # Get all panes with their commands
    while IFS= read -r line; do
        # Format: window_index:pane_index command
        panes+=("$line")
    done < <(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_pid}" | \
             grep -iE "(oc|opencode|claude|node.*opencode)" || true)
    
    printf '%s\n' "${panes[@]}"
}

# Get icon for state
get_state_icon() {
    local state="$1"
    local icon_idle=$(get_tmux_option "@opencode_icon_idle" "○")
    local icon_busy=$(get_tmux_option "@opencode_icon_busy" "●")
    local icon_waiting=$(get_tmux_option "@opencode_icon_waiting" "◉")
    local icon_error=$(get_tmux_option "@opencode_icon_error" "✗")
    
    case "$state" in
        idle)    echo "$icon_idle" ;;
        busy)    echo "$icon_busy" ;;
        waiting) echo "$icon_waiting" ;;
        error)   echo "$icon_error" ;;
        *)       echo "○" ;;
    esac
}

# Get color for state
get_state_color() {
    local state="$1"
    local color_idle=$(get_tmux_option "@opencode_color_idle" "green")
    local color_busy=$(get_tmux_option "@opencode_color_busy" "yellow")
    local color_waiting=$(get_tmux_option "@opencode_color_waiting" "cyan")
    local color_error=$(get_tmux_option "@opencode_color_error" "red")
    
    case "$state" in
        idle)    echo "$color_idle" ;;
        busy)    echo "$color_busy" ;;
        waiting) echo "$color_waiting" ;;
        error)   echo "$color_error" ;;
        *)       echo "white" ;;
    esac
}

# Main status display function
print_opencode_status() {
    local show_session_name=$(get_tmux_option "@opencode_show_session_name" "false")
    local separator=$(get_tmux_option "@opencode_separator" " ")
    local output=""
    local count=0
    
    # Find all OpenCode panes
    local panes=$(find_opencode_panes)
    
    if [ -z "$panes" ]; then
        # No OpenCode sessions found
        local no_session_text=$(get_tmux_option "@opencode_no_session_text" "")
        echo "$no_session_text"
        return
    fi
    
    # Process each pane
    while IFS= read -r pane_line; do
        [ -z "$pane_line" ] && continue
        
        local pane_target=$(echo "$pane_line" | awk '{print $1}')
        local session_name=$(echo "$pane_target" | cut -d: -f1)
        local window_pane=$(echo "$pane_target" | cut -d: -f2)
        
        # Detect state
        local state=$(detect_session_state "$pane_target")
        local icon=$(get_state_icon "$state")
        local color=$(get_state_color "$state")
        
        # Build display string
        local display_item="#[fg=$color]$icon#[default]"
        
        if [ "$show_session_name" == "true" ]; then
            display_item="${display_item}#[fg=$color]${session_name:0:3}#[default]"
        fi
        
        # Add separator if not first item
        if [ $count -gt 0 ]; then
            output="${output}${separator}"
        fi
        
        output="${output}${display_item}"
        ((count++))
    done <<< "$panes"
    
    # Add count prefix if enabled
    local show_count=$(get_tmux_option "@opencode_show_count" "true")
    if [ "$show_count" == "true" ] && [ $count -gt 0 ]; then
        local prefix=$(get_tmux_option "@opencode_prefix" "OC:")
        output="${prefix}${count} ${output}"
    fi
    
    echo "$output"
}

main() {
    print_opencode_status
}

main
