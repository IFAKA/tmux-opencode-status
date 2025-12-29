#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# Get content hash for caching (lightweight fingerprint)
get_content_hash() {
    local pane_id="$1"
    # Get just the last line and its timestamp for quick comparison
    # This avoids hashing entire content
    tmux capture-pane -p -t "$pane_id" -S -1 2>/dev/null | cksum | cut -d' ' -f1
}

# State detection for OpenCode sessions
# States: idle, busy, waiting, error
detect_session_state() {
    local pane_id="$1"
    local use_cache="${2:-true}"
    
    # Check cache first (if enabled)
    if [ "$use_cache" = "true" ]; then
        local cached=$(get_cached_state "$pane_id")
        local cache_ttl=$(get_tmux_option "@opencode_cache_ttl" "5")
        
        if is_cache_valid "$cached" "$cache_ttl"; then
            # Cache is valid, check if content changed
            local cached_hash=$(echo "$cached" | cut -d: -f3)
            local current_hash=$(get_content_hash "$pane_id")
            
            if [ "$cached_hash" = "$current_hash" ]; then
                # Content unchanged, return cached state
                get_state_from_cache "$cached"
                return
            fi
        fi
    fi
    
    # Cache miss or invalid - detect state
    local pane_content
    local last_lines
    
    # Capture only last 20 lines for efficiency (reduced from 100)
    last_lines=$(tmux capture-pane -p -t "$pane_id" -S -20 2>/dev/null || echo "")
    
    # Early exit if pane is empty
    if [ -z "$last_lines" ]; then
        echo "idle"
        return
    fi
    
    local detected_state="idle"
    
    # Check for various states (most specific first)
    # Using single grep with -m1 for efficiency (stops at first match)
    
    # Error state - look for error messages in recent output
    if echo "$last_lines" | grep -m1 -qiE "(✗|error:|failed|exception|fatal|Error:|Failed)"; then
        detected_state="error"
    
    # Waiting for input - look for permission prompts and confirmations
    # OpenCode specific patterns: permission requests, y/n prompts
    elif echo "$last_lines" | grep -m1 -qiE "(y/n|yes/no|continue\?|proceed\?|\[Y/n\]|\(y/N\)|permission|allow|approve|confirm)"; then
        detected_state="waiting"
    
    # Busy state - look for activity indicators
    # Check for: spinners, "working", thinking indicators, tool execution
    elif echo "$last_lines" | grep -m1 -qE "(●|◐|◓|◑|◒|⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|loading|processing|running|executing|working|analyzing|searching|thinking|calling|invoking|\.\.\.|…)"; then
        detected_state="busy"
    
    # Check cursor position - if at bottom with prompt, likely idle
    # Look for common shell prompts or ready state
    elif echo "$last_lines" | tail -3 | grep -qE "(>|❯|\$|#|%)"; then
        detected_state="idle"
    fi
    
    # Cache the result with content hash
    if [ "$use_cache" = "true" ]; then
        local content_hash=$(get_content_hash "$pane_id")
        local timestamp=$(get_timestamp)
        local cache_file="$(get_cache_dir)/$(echo "$pane_id" | sed 's/[^a-zA-Z0-9]/_/g')"
        echo "${timestamp}:${detected_state}:${content_hash}" > "$cache_file"
    fi
    
    echo "$detected_state"
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
    local enable_cache=$(get_tmux_option "@opencode_enable_cache" "true")
    local output=""
    local count=0
    
    # Clean old cache files periodically
    if [ "$enable_cache" = "true" ]; then
        clean_old_cache
    fi
    
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
        
        local pane_target="$pane_line"
        local session_name=$(echo "$pane_target" | cut -d: -f1)
        local window_pane=$(echo "$pane_target" | cut -d: -f2)
        
        # Detect state (with caching)
        local state=$(detect_session_state "$pane_target" "$enable_cache")
        local icon=$(get_state_icon "$state")
        local color=$(get_state_color "$state")
        
        # Build display string
        local display_item="#[fg=$color]$icon#[default]"
        
        if [ "$show_session_name" = "true" ]; then
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
    if [ "$show_count" = "true" ] && [ $count -gt 0 ]; then
        local prefix=$(get_tmux_option "@opencode_prefix" "OC:")
        output="${prefix}${count} ${output}"
    fi
    
    echo "$output"
}

main() {
    print_opencode_status
}

# Only run main if script is executed directly, not when sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
