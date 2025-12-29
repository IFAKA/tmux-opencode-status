#!/usr/bin/env bash
# tmux-opencode-status - Simple OpenCode monitor

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set default icons
tmux set-option -gq @opencode_icon_idle "○"
tmux set-option -gq @opencode_icon_busy "●"
tmux set-option -gq @opencode_icon_waiting "◉"
tmux set-option -gq @opencode_icon_error "✗"

# Run monitor periodically
tmux set-option -g status-right "#($PLUGIN_DIR/scripts/opencode_monitor.sh)$(tmux show-option -gv status-right)"
