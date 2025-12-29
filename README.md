# tmux-opencode-status

Monitor all your OpenCode/Claude Code sessions at a glance - **directly in your tmux window tabs**.

## Features

- **Window-Based Display:** Each tmux window shows its OpenCode state icon right in the tab name
- **Visual State Indicators:** See which OpenCode sessions are idle, busy, waiting for input, or errored
- **At-a-Glance Monitoring:** No need to switch windows to check session status
- **One-Window Philosophy:** Perfect for users who prefer multiple windows over split panes
- **Customizable:** Configure icons, colors, and display format to match your style
- **Lightweight:** Pure Bash, no dependencies, minimal performance impact
- **Two Display Modes:** Window-based (recommended) or status bar (legacy)

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
set -g @plugin 'IFAKA/tmux-opencode-status'
```

Press `prefix + I` to fetch and source the plugin.

### Manual Installation

Clone the repository:

```bash
git clone https://github.com/IFAKA/tmux-opencode-status ~/.tmux/plugins/tmux-opencode-status
```

Add to your `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-opencode-status/opencode-status.tmux
```

Reload tmux configuration:

```bash
tmux source-file ~/.tmux.conf
```

## Display Modes

### Window-Based Display (Recommended)

Each tmux window shows its OpenCode state directly in the window name:

```
[session] 0:frontend○ 1:backend● 2:docs◉
```

Perfect for the **one-window philosophy** - run one OpenCode per window and see all states in your window list!

**Configuration:**
```tmux
set -g @plugin 'IFAKA/tmux-opencode-status'

# Enable automatic window renaming
setw -g automatic-rename on

# Status bar runs the monitor (returns empty, updates window names)
set -g status-right '#($HOME/.tmux/plugins/tmux-opencode-status/scripts/window_monitor.sh)%H:%M %d-%b'
```

### Status Bar Display (Legacy)

Shows all OpenCode sessions in the status bar:

```
OC:3 ○ ● ◉ | 14:30
```

**Configuration:**
```tmux
set -g @plugin 'IFAKA/tmux-opencode-status'
set -g status-right '#{opencode_status} | %H:%M %d-%b'
```

## Quick Start (Window-Based Display)

1. **Install the plugin** (see Installation section below)

2. **Add to your `.tmux.conf`:**
   ```tmux
   set -g @plugin 'IFAKA/tmux-opencode-status'
   setw -g automatic-rename on
   set -g status-right '#($HOME/.tmux/plugins/tmux-opencode-status/scripts/window_monitor.sh)%H:%M'
   ```

3. **Reload tmux config:**
   ```bash
   tmux source-file ~/.tmux.conf
   ```

4. **Create windows and start OpenCode:**
   ```bash
   # Window 0
   oc
   # Name it: Ctrl+b then , → type "frontend"
   
   # Create new window: Ctrl+b then c
   oc
   # Name it: Ctrl+b then , → type "backend"
   ```

5. **See the magic:**
   ```
   [session] 0:frontend○ 1:backend●
   ```
   
   Each window shows its own OpenCode state!

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

### Performance Options

```tmux
set -g @opencode_enable_cache "true"         # Enable smart caching (recommended)
set -g @opencode_cache_ttl "5"               # Cache validity in seconds
```

**Cache behavior:**
- When enabled, the plugin only re-analyzes panes when their content changes
- Dramatically reduces CPU usage with multiple OpenCode sessions
- Safe to keep enabled (default)

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

The plugin uses an optimized polling approach with intelligent caching:

1. **Scans** all tmux panes for OpenCode/Claude Code processes
2. **Checks cache** - if pane content unchanged, returns cached state (skips analysis)
3. **Analyzes** pane content only when changed to detect current state:
   - **Idle:** OpenCode prompt visible, no activity
   - **Busy:** Processing indicators (loading, analyzing, etc.)
   - **Waiting:** Prompts for user input (y/n, confirmations)
   - **Error:** Error messages detected in output
4. **Caches** the result with content fingerprint
5. **Displays** a colored icon for each session
6. **Updates** automatically based on your tmux `status-interval` setting

**Performance:**
- With caching enabled, unchanged panes are skipped (no grep/analysis)
- Content fingerprinting is fast (single line checksum)
- Typical overhead: <10ms per update cycle with 3-5 sessions

## Performance & Caching

The plugin uses intelligent caching to minimize CPU usage:
- **Smart caching:** Only re-analyzes panes when content changes
- **Efficient detection:** Uses optimized pattern matching
- **Automatic cleanup:** Old cache files cleaned periodically

### Recommended Update Intervals

The plugin works efficiently with standard tmux intervals:

```tmux
# Balanced (recommended) - good responsiveness, low CPU
set -g status-interval 10

# Faster updates - more responsive, slightly higher CPU
set -g status-interval 5

# Slower updates - minimal CPU usage
set -g status-interval 15  # tmux default
```

**Note:** With caching enabled, the plugin skips work when pane content hasn't changed, so even 5-second intervals are efficient.

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
