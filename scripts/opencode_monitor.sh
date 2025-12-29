#!/usr/bin/env bash
# Simple OpenCode monitor for tmux - shows state in window names

get_option() {
    tmux show-option -gqv "$1" || echo "$2"
}

detect_state() {
    local content=$(tmux capture-pane -p -t "$1" -S -20 2>/dev/null)
    
    if echo "$content" | grep -qiE "(error:|failed|exception)"; then
        echo "error"
    elif echo "$content" | grep -qiE "(y/n|\[Y/n\]|confirm)"; then
        echo "waiting"
    elif echo "$content" | grep -qE "(loading|processing|\.\.\.)"; then
        echo "busy"
    else
        echo "idle"
    fi
}

get_icon() {
    case "$1" in
        idle)    get_option "@opencode_icon_idle" "○" ;;
        busy)    get_option "@opencode_icon_busy" "●" ;;
        waiting) get_option "@opencode_icon_waiting" "◉" ;;
        error)   get_option "@opencode_icon_error" "✗" ;;
    esac
}

is_opencode() {
    local cmd=$(tmux list-panes -t "$1" -F "#{pane_current_command}" 2>/dev/null)
    echo "$cmd" | grep -qiE "^(oc|opencode)$"
}

strip_icon() {
    echo "$1" | sed -E 's/ [○●◉✗].*$//'
}

tmux list-windows -F "#{session_name}:#{window_index} #{window_name}" 2>/dev/null | while read window name; do
    base=$(strip_icon "$name")
    pane="${window}.1"
    
    if is_opencode "$pane"; then
        icon=$(get_icon $(detect_state "$pane"))
        new="${base} ${icon}"
        [ "$name" != "$new" ] && tmux rename-window -t "$window" "$new"
    else
        [ "$name" != "$base" ] && tmux rename-window -t "$window" "$base"
    fi
done
