# tmux-opencode-status

Show OpenCode state in tmux window names.

```
0:frontend ○  1:backend ●  2:docs ◉
```

## States

- `○` Idle
- `●` Busy (loading)
- `◉` Waiting (permission)
- `✗` Error

## Install

```bash
git clone https://github.com/IFAKA/tmux-opencode-status ~/.tmux/plugins/tmux-opencode-status
echo "run-shell ~/.tmux/plugins/tmux-opencode-status/opencode-status.tmux" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## License

MIT
