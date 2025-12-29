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

# Cache directory management
get_cache_dir() {
    local cache_dir="${TMPDIR:-/tmp}/tmux-opencode-status-${EUID}"
    if [ ! -d "$cache_dir" ]; then
        mkdir -p "$cache_dir" 2>/dev/null
        chmod 700 "$cache_dir" 2>/dev/null
    fi
    echo "$cache_dir"
}

# Get current timestamp
get_timestamp() {
    date +%s
}

# Get cached state for a pane
# Returns: "timestamp:state" or empty if no cache
get_cached_state() {
    local pane_id="$1"
    local cache_file="$(get_cache_dir)/$(echo "$pane_id" | sed 's/[^a-zA-Z0-9]/_/g')"
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    fi
}

# Set cached state for a pane
set_cached_state() {
    local pane_id="$1"
    local state="$2"
    local cache_file="$(get_cache_dir)/$(echo "$pane_id" | sed 's/[^a-zA-Z0-9]/_/g')"
    local timestamp=$(get_timestamp)
    
    echo "${timestamp}:${state}" > "$cache_file"
}

# Check if cache is still valid (within N seconds)
is_cache_valid() {
    local cached_data="$1"
    local max_age="${2:-10}"  # Default: cache valid for 10 seconds
    
    if [ -z "$cached_data" ]; then
        return 1
    fi
    
    local cached_timestamp=$(echo "$cached_data" | cut -d: -f1)
    local current_timestamp=$(get_timestamp)
    local age=$((current_timestamp - cached_timestamp))
    
    [ "$age" -lt "$max_age" ]
}

# Get state from cached data
get_state_from_cache() {
    local cached_data="$1"
    echo "$cached_data" | cut -d: -f2-
}

# Clean old cache files (older than 1 hour)
clean_old_cache() {
    local cache_dir="$(get_cache_dir)"
    find "$cache_dir" -type f -mmin +60 -delete 2>/dev/null
}
