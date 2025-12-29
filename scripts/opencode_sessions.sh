#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# State detection for OpenCode sessions
# States: idle, busy, waiting, error
detect_session_state() {
    local pane_id="$1"
    local pane_content
    local last_lines
    
    # Capture pane content - last 100 lines for context
    pane_content=$(tmux capture-pane -p -t "$pane_id" -S -100 2>/dev/null || echo "")
    last_lines=$(echo "$pane_content" | tail -20)
    
    # Check for various states (most specific first)
    
    # Error state - look for error messages in recent output
    if echo "$last_lines" | grep -qiE "(✗|error:|failed|exception|fatal|Error:|Failed)"; then
        echo "error"
        return
    fi
    
    # Waiting for input - look for permission prompts and confirmations
    # OpenCode specific patterns: permission requests, y/n prompts
    if echo "$last_lines" | grep -qiE "(y/n|yes/no|continue\?|proceed\?|\[Y/n\]|\(y/N\)|permission|allow|approve|confirm)"; then
        echo "waiting"
        return
    fi
    
    # Busy state - look for activity indicators
    # Check for: spinners, "working", thinking indicators, tool execution
    if echo "$last_lines" | grep -qiE "(●|◐|◓|◑|◒|⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|loading|processing|running|executing|working|analyzing|searching|thinking|calling|invoking)"; then
        echo "busy"
        return
    fi
    
    # Check for ellipsis/dots indicating processing
    if echo "$last_lines" | grep -qE "\.\.\.|…"; then
        echo "busy"
        return
    fi
    
    # Check cursor position - if at bottom with prompt, likely idle
    # Look for common shell prompts or ready state
    if echo "$last_lines" | tail -3 | grep -qE "(>|❯|\$|#|%)"; then
        echo "idle"
        return
    fi
    
    # Default to idle if we can't determine state
    echo "idle"
}

# Find all panes running OpenCode
find_opencode_panes() {
    # Get all panes and check for OpenCode processes
    # Check both the command name and the full command line
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_pid}" | \
    while IFS= read -r line; do
        local pane_target=$(echo "$line" | awk '{print $1}')
        local pane_command=$(echo "$line" | awk '{print $2}')
        local pane_pid=$(echo "$line" | awk '{print $3}')
        
        # Check if command matches OpenCode patterns
        if echo "$pane_command" | grep -qiE "^(oc|opencode|node)$"; then
            # For node processes, verify it's actually running OpenCode
            if [ "$pane_command" = "node" ]; then
                if ps -p "$pane_pid" -o command= 2>/dev/null | grep -qiE "(opencode|oc)"; then
                    echo "$pane_target"
                fi
            else
                echo "$pane_target"
            fi
        fi
    done
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
