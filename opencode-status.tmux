#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

# Interpolation strings
opencode_interpolation=(
    "\#{opencode_status}"
)

# Corresponding commands
opencode_commands=(
    "#($CURRENT_DIR/scripts/opencode_sessions.sh)"
)

# String interpolation function
do_interpolation() {
    local all_interpolated="$1"
    for ((i=0; i<${#opencode_commands[@]}; i++)); do
        all_interpolated=${all_interpolated//${opencode_interpolation[$i]}/${opencode_commands[$i]}}
    done
    echo "$all_interpolated"
}

# Update tmux option with interpolated values
update_tmux_option() {
    local option="$1"
    local option_value="$(get_tmux_option "$option")"
    local new_option_value="$(do_interpolation "$option_value")"
    set_tmux_option "$option" "$new_option_value"
}

main() {
    # Update both status-right and status-left to support either placement
    update_tmux_option "status-right"
    update_tmux_option "status-left"
}

main
