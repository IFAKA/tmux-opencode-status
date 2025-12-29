#!/usr/bin/env bash

# Standard tmux option getter
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value="$(tmux show-option -gqv "$option")"
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Set tmux option
set_tmux_option() {
    local option="$1"
    local value="$2"
    tmux set-option -gq "$option" "$value"
}

# Platform detection
is_osx() {
    [ "$(uname)" == "Darwin" ]
}

is_linux() {
    [ "$(uname)" == "Linux" ]
}

# Command existence check
command_exists() {
    local command="$1"
    command -v "$command" &>/dev/null
}
