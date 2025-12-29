# tmux-opencode-status

Monitor all your OpenCode/Claude Code sessions at a glance directly in your tmux status bar.

## Features

- **Visual State Indicators:** See which OpenCode sessions are idle, busy, waiting for input, or errored
- **At-a-Glance Monitoring:** No need to split terminals or switch panes to check session status
- **One-Line Display:** Compact, information-dense status bar integration
- **Customizable:** Configure icons, colors, and display format to match your style
- **Lightweight:** Pure Bash, no dependencies, minimal performance impact

## States

| State | Default Icon | Default Color | Meaning |
|-------|--------------|---------------|---------|
| **Idle** | `○` | Green | OpenCode is ready for input |
| **Busy** | `●` | Yellow | OpenCode is processing/thinking |
| **Waiting** | `◉` | Cyan | OpenCode is waiting for your input (y/n, confirmation, etc.) |
| **Error** | `✗` | Red | An error occurred in the session |

## Installation

### With [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (Recommended)

Add to your `.tmux.conf`:

```tmux
set -g @plugin 'yourusername/tmux-opencode-status'
```

Press `prefix + I` to fetch and source the plugin.

### Manual Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/tmux-opencode-status ~/.tmux/plugins/tmux-opencode-status
```

Add to your `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-opencode-status/opencode-status.tmux
```

Reload tmux configuration:

```bash
tmux source-file ~/.tmux.conf
```

## Quick Start

1. **Install the plugin** (see Installation section below)

2. **Add to your `.tmux.conf`:**
   ```tmux
   set -g status-right '#{opencode_status} | %H:%M %d-%b-%y'
   ```

3. **Reload tmux config:**
   ```bash
   tmux source-file ~/.tmux.conf
   ```

4. **Start using OpenCode** in any tmux pane - the status bar will automatically show:
   ```
   OC:3 ○ ● ◉
   ```

## Usage

Add `#{opencode_status}` to your status bar in `.tmux.conf`:

```tmux
set -g status-right '#{opencode_status} | %H:%M %d-%b-%y'
```

Or in status-left:

```tmux
set -g status-left '#{opencode_status} | [#S] '
```

### Example Output

```
OC:3 ○ ● ◉
```

This shows:
- 3 OpenCode sessions total
- First session: idle (ready)
- Second session: busy (processing)
- Third session: waiting for input

### State Meanings

- **○ Idle (Green):** OpenCode is ready and waiting for your input
- **● Busy (Yellow):** OpenCode is processing, thinking, or executing tools
- **◉ Waiting (Cyan):** OpenCode is waiting for your confirmation (y/n prompts, permissions)
- **✗ Error (Red):** An error occurred in the session

## Configuration

All options are optional and have sensible defaults.

### Icons

```tmux
set -g @opencode_icon_idle "○"      # Idle state icon
set -g @opencode_icon_busy "●"      # Busy/processing icon
set -g @opencode_icon_waiting "◉"   # Waiting for input icon
set -g @opencode_icon_error "✗"     # Error state icon
```

### Colors

```tmux
set -g @opencode_color_idle "green"     # Idle state color
set -g @opencode_color_busy "yellow"    # Busy state color
set -g @opencode_color_waiting "cyan"   # Waiting state color
set -g @opencode_color_error "red"      # Error state color
```

Supports tmux color names: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, or `colour0-colour255`.

### Display Options

```tmux
set -g @opencode_show_count "true"           # Show session count prefix
set -g @opencode_prefix "OC:"                # Prefix text before count
set -g @opencode_separator " "               # Separator between session indicators
set -g @opencode_show_session_name "false"   # Show abbreviated session name
set -g @opencode_no_session_text ""          # Text to display when no sessions found
```

### Full Configuration Example

```tmux
# Install plugin
set -g @plugin 'yourusername/tmux-opencode-status'

# Customize icons (use emoji or Unicode)
set -g @opencode_icon_idle "💤"
set -g @opencode_icon_busy "⚙️"
set -g @opencode_icon_waiting "❓"
set -g @opencode_icon_error "❌"

# Customize colors
set -g @opencode_color_idle "colour2"
set -g @opencode_color_busy "colour3"
set -g @opencode_color_waiting "colour6"
set -g @opencode_color_error "colour1"

# Display options
set -g @opencode_show_count "true"
set -g @opencode_prefix "OpenCode:"
set -g @opencode_separator " • "

# Add to status bar
set -g status-right '#{opencode_status} | %H:%M'
```

## How It Works

The plugin:

1. Scans all tmux panes for OpenCode/Claude Code processes
2. Analyzes pane content to detect current state:
   - **Idle:** OpenCode prompt visible, no activity
   - **Busy:** Processing indicators (loading, analyzing, etc.)
   - **Waiting:** Prompts for user input (y/n, confirmations)
   - **Error:** Error messages detected in output
3. Displays a colored icon for each session
4. Updates automatically based on your tmux `status-interval` setting

## Tips

### Adjust Update Frequency

By default, tmux updates the status bar every 15 seconds. For more responsive OpenCode monitoring, set a shorter interval:

```tmux
set -g status-interval 5  # Update every 5 seconds
```

### Combine with Other Plugins

Works great with other tmux plugins:

```tmux
set -g status-right '#{opencode_status} | CPU: #{cpu_percentage} | %H:%M'
```

### Keyboard Shortcut to Jump to Waiting Sessions

Add a binding to quickly find sessions waiting for input:

```tmux
bind-key o run-shell "tmux list-panes -a -F '#{pane_id}' | xargs -I {} tmux capture-pane -p -t {} | grep -l 'y/n' | head -1 | xargs tmux select-pane -t"
```

## Troubleshooting

### Debug Mode

Run the debug script to see detailed information about detected sessions:

```bash
~/.tmux/plugins/tmux-opencode-status/scripts/debug.sh
```

This will show:
- Current tmux configuration
- Plugin configuration
- All tmux panes
- Detected OpenCode panes
- State detection for each pane
- Final status output

### Common Issues

**No sessions detected:**
- Ensure OpenCode is actually running in a tmux pane
- Check that the process name matches expected patterns (oc, opencode, node)
- Run the debug script to see all panes and their commands
- Verify with: `ps aux | grep -i opencode`

**States not updating:**
- Increase update frequency with `set -g status-interval 5`
- Check that pane content is accessible (not in alternate screen mode)
- Run debug script to see current state detection

**Icons not displaying:**
- Ensure your terminal supports Unicode characters
- Try simpler ASCII icons if Unicode doesn't work:
  ```tmux
  set -g @opencode_icon_idle "."
  set -g @opencode_icon_busy "*"
  set -g @opencode_icon_waiting "?"
  set -g @opencode_icon_error "X"
  ```

**State detection seems wrong:**
- The plugin analyzes pane content to detect states
- Some applications may interfere with content capture
- Try increasing the update interval for more accurate detection

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT License - see LICENSE file for details

## Related Projects

- [OpenCode](https://opencode.ai) - The AI coding assistant this plugin monitors
- [tmux-plugins](https://github.com/tmux-plugins) - Collection of tmux plugins

---

**Made for developers who run multiple OpenCode sessions and want to stay in the flow.**
