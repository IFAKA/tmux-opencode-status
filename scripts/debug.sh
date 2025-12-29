#!/usr/bin/env bash

# Debug script to help troubleshoot OpenCode session detection

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/opencode_sessions.sh"

main() {
    echo "=== tmux-opencode-status Debug Info ==="
    echo ""

    echo "1. Tmux Configuration:"
    echo "   status-interval: $(tmux show-option -gv status-interval)"
    echo "   status-right: $(tmux show-option -gv status-right)"
    echo ""

    echo "2. Plugin Configuration:"
    echo "   @opencode_show_count: $(get_tmux_option "@opencode_show_count" "true")"
    echo "   @opencode_prefix: $(get_tmux_option "@opencode_prefix" "OC:")"
    echo "   @opencode_separator: $(get_tmux_option "@opencode_separator" " ")"
    echo "   @opencode_icon_idle: $(get_tmux_option "@opencode_icon_idle" "○")"
    echo "   @opencode_icon_busy: $(get_tmux_option "@opencode_icon_busy" "●")"
    echo "   @opencode_icon_waiting: $(get_tmux_option "@opencode_icon_waiting" "◉")"
    echo "   @opencode_icon_error: $(get_tmux_option "@opencode_icon_error" "✗")"
    echo ""

    echo "3. All tmux panes:"
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_pid}"
    echo ""

    echo "4. Detected OpenCode panes:"
    local panes=$(find_opencode_panes)
    if [ -z "$panes" ]; then
        echo "   ⚠️  No OpenCode panes detected"
        echo ""
        echo "   Troubleshooting:"
        echo "   - Ensure OpenCode is running in a tmux pane"
        echo "   - Check that the process name contains: oc, opencode, or node"
        echo "   - Run: ps aux | grep -i opencode"
    else
        echo "$panes"
        echo ""
        
        echo "5. State detection for each pane:"
        while IFS= read -r pane_target; do
            [ -z "$pane_target" ] && continue
            local state=$(detect_session_state "$pane_target")
            local icon=$(get_state_icon "$state")
            local color=$(get_state_color "$state")
            echo "   Pane: $pane_target"
            echo "   State: $state ($icon in $color)"
            echo "   Last 5 lines:"
            tmux capture-pane -p -t "$pane_target" -S -5 2>/dev/null | sed 's/^/      /'
            echo ""
        done <<< "$panes"
    fi

    echo "6. Final status output:"
    echo "   $(print_opencode_status)"
    echo ""

    echo "=== End Debug Info ==="
}

main
