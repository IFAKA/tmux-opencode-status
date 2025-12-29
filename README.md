# tmux-opencode-status

Simple OpenCode monitor for tmux. Shows status in window names.

```
0:frontend ○  1:backend ●  2:docs ◉
```

## States

- `○` Idle (ready)
- `●` Busy (processing)
- `◉` Waiting (needs input)
- `✗` Error

## Install

**TPM:**
```tmux
set -g @plugin 'IFAKA/tmux-opencode-status'
```

**Manual:**
```bash
git clone https://github.com/IFAKA/tmux-opencode-status ~/.tmux/plugins/tmux-opencode-status
echo "run-shell ~/.tmux/plugins/tmux-opencode-status/opencode-status.tmux" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## Usage

```bash
tmux
opencode
# Wait 10 seconds - icon appears automatically
```

## Config

```tmux
# Custom icons (optional)
set -g @opencode_icon_idle "."
set -g @opencode_icon_busy "*"
set -g @opencode_icon_waiting "?"
set -g @opencode_icon_error "!"

# Update frequency (optional, default: 10)
set -g status-interval 5
```

## How it works

1. Runs every `status-interval` seconds
2. Detects OpenCode in tmux windows
3. Checks pane content for state
4. Updates window name with icon

## Troubleshooting

**No icon?**
- OpenCode must run inside tmux
- Wait 10 seconds for update

**Test manually:**
```bash
~/.tmux/plugins/tmux-opencode-status/scripts/opencode_monitor.sh
tmux list-windows
```

## License

MIT
