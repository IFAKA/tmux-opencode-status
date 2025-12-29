#!/usr/bin/env bash

# Simple wrapper to run window name updates
# This is what gets executed by tmux's status-interval

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the window name updater silently
"$CURRENT_DIR/update_window_names.sh" 2>/dev/null

# Return empty string (we're not displaying anything in status bar)
echo ""
