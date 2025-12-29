#!/usr/bin/env bash
# Simple OpenCode state monitor for tmux window names
# States: idle (○), busy (●), waiting (◉), error (✗)

# Icons
ICON_IDLE="○"
ICON_BUSY="●"
ICON_WAITING="◉"
ICON_ERROR="✗"

# Detect state from pane content
detect_state() {
    local pane_id="$1"
    local lines=$(tmux capture-pane -p -t "$pane_id" -S -15 2>/dev/null)

    [ -z "$lines" ] && echo "idle" && return

    # Error
    if echo "$lines" | grep -qiE "(✗|error:|failed|exception|fatal|panic:)"; then
        echo "error"
    # Permission/confirmation prompt
    elif echo "$lines" | grep -qiE "(\[Y/n\]|\[y/N\]|y/n|Allow|Deny|permission|approve|confirm)"; then
        echo "waiting"
    # Busy/loading
    elif echo "$lines" | grep -qE "(⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|●|◐|◓|◑|◒|thinking|Thinking|Tool:|\.\.\.|\.\.\.$)"; then
        echo "busy"
    else
        echo "idle"
    fi
}

# Get icon for state
get_icon() {
    case "$1" in
        idle)    echo "$ICON_IDLE" ;;
        busy)    echo "$ICON_BUSY" ;;
        waiting) echo "$ICON_WAITING" ;;
        error)   echo "$ICON_ERROR" ;;
        *)       echo "$ICON_IDLE" ;;
    esac
}

# Strip existing icon from window name
strip_icon() {
    echo "$1" | sed -E 's/ [○●◉✗]$//'
}

# Check if pane runs opencode
is_opencode() {
    local cmd="$1"
    local pid="$2"

    if echo "$cmd" | grep -qiE "^(oc|opencode)$"; then
        return 0
    elif [ "$cmd" = "node" ]; then
        ps -p "$pid" -o command= 2>/dev/null | grep -qiE "(opencode|oc)" && return 0
    fi
    return 1
}

# Main: update all window names
main() {
    tmux list-windows -F "#{window_index} #{window_name}" | while read -r idx name; do
        local pane_info=$(tmux list-panes -t ":$idx" -F "#{pane_id} #{pane_current_command} #{pane_pid}" | head -1)
        local pane_id=$(echo "$pane_info" | awk '{print $1}')
        local pane_cmd=$(echo "$pane_info" | awk '{print $2}')
        local pane_pid=$(echo "$pane_info" | awk '{print $3}')

        local base_name=$(strip_icon "$name")

        if is_opencode "$pane_cmd" "$pane_pid"; then
            local state=$(detect_state "$pane_id")
            local icon=$(get_icon "$state")
            local new_name="$base_name $icon"
            [ "$name" != "$new_name" ] && tmux rename-window -t ":$idx" "$new_name"
        else
            [ "$name" != "$base_name" ] && tmux rename-window -t ":$idx" "$base_name"
        fi
    done
}

main
