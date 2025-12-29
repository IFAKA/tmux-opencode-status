#!/usr/bin/env bash
# Simple OpenCode state monitor for tmux window names
# States: idle (○), busy (●), waiting (◉), error (✗)

ICON_IDLE="○"
ICON_BUSY="●"
ICON_WAITING="◉"
ICON_ERROR="✗"

# Detect state from pane content
detect_state() {
    local pane_id="$1"
    local lines=$(tmux capture-pane -p -t "$pane_id" -S -15 2>/dev/null)

    [ -z "$lines" ] && echo "idle" && return

    if echo "$lines" | grep -qiE "(✗|error:|failed|exception|fatal|panic:)"; then
        echo "error"
    elif echo "$lines" | grep -qiE "(\[Y/n\]|\[y/N\]|y/n|Allow|Deny|permission|approve|confirm)"; then
        echo "waiting"
    elif echo "$lines" | grep -qE "(⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|●|◐|◓|◑|◒|thinking|Thinking|Tool:|\.\.\.|\.\.\.$)"; then
        echo "busy"
    else
        echo "idle"
    fi
}

get_icon() {
    case "$1" in
        idle)    echo "$ICON_IDLE" ;;
        busy)    echo "$ICON_BUSY" ;;
        waiting) echo "$ICON_WAITING" ;;
        error)   echo "$ICON_ERROR" ;;
        *)       echo "$ICON_IDLE" ;;
    esac
}

# Strip all existing icons from window name
strip_icons() {
    echo "$1" | sed -E 's/ [○●◉✗]+$//'
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

# Main: update window names with icons for each opencode pane
main() {
    tmux list-windows -F "#{window_index} #{window_name}" | while read -r idx name; do
        local icons=""

        # Check ALL panes in this window
        while IFS= read -r pane_line; do
            local pane_id=$(echo "$pane_line" | awk '{print $1}')
            local pane_cmd=$(echo "$pane_line" | awk '{print $2}')
            local pane_pid=$(echo "$pane_line" | awk '{print $3}')

            if is_opencode "$pane_cmd" "$pane_pid"; then
                local state=$(detect_state "$pane_id")
                local icon=$(get_icon "$state")
                icons="${icons}${icon}"
            fi
        done < <(tmux list-panes -t ":$idx" -F "#{pane_id} #{pane_current_command} #{pane_pid}")

        local base_name=$(strip_icons "$name")

        if [ -n "$icons" ]; then
            local new_name="$base_name $icons"
            [ "$name" != "$new_name" ] && tmux rename-window -t ":$idx" "$new_name"
        else
            # No opencode in this window - restore base name if needed
            [ "$name" != "$base_name" ] && tmux rename-window -t ":$idx" "$base_name"
        fi
    done
}

main
