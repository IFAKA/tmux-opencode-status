# Contributing to tmux-opencode-status

First off, thank you for considering contributing to tmux-opencode-status! 

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Run the debug script** (`scripts/debug.sh`) and include the output
- **Describe the behavior you observed** and what you expected
- **Include your tmux version**: `tmux -V`
- **Include your OS**: macOS version or Linux distribution

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List any examples** of how it would be used

### Pull Requests

1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test your changes thoroughly
5. Follow the existing code style (Bash best practices)
6. Update documentation if needed
7. Commit with a clear message describing your changes
8. Push to your fork
9. Submit a pull request

## Development Guidelines

### Code Style

- Follow standard Bash scripting best practices
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small
- Use `local` for function variables
- Quote variables to prevent word splitting
- Use `#!/usr/bin/env bash` for scripts

### Testing

Before submitting:

1. Run syntax check: `bash -n script_name.sh`
2. Test the plugin manually with tmux
3. Run the debug script to verify detection works
4. Test on both macOS and Linux if possible
5. Test with different OpenCode states (idle, busy, waiting, error)

### File Organization

```
tmux-opencode-status/
├── opencode-status.tmux     # Main entry point
├── scripts/
│   ├── helpers.sh           # Shared utilities
│   ├── opencode_sessions.sh # Core functionality
│   ├── debug.sh             # Debug tooling
│   └── test.sh              # Testing script
├── examples/
│   └── tmux.conf.example    # Example configuration
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests liberally after the first line

Example:
```
Add support for custom separators

- Allow users to configure separator between session indicators
- Add @opencode_separator option
- Update README with examples

Closes #123
```

## State Detection Logic

When improving state detection, consider:

1. **Priority order** (most specific first):
   - Error state (errors, failures)
   - Waiting state (permission prompts, y/n questions)
   - Busy state (processing, thinking, loading)
   - Idle state (default)

2. **Pattern matching**:
   - Use `grep -E` for extended regex
   - Match case-insensitively when appropriate (`-i`)
   - Be specific but not too restrictive

3. **Performance**:
   - Capture only necessary lines from panes
   - Use efficient grep patterns
   - Consider caching if needed

## Adding New Features

When adding new features:

1. **Configuration options** should:
   - Use `@opencode_*` prefix
   - Have sensible defaults
   - Be documented in README

2. **Icons and colors** should:
   - Support user customization
   - Have Unicode and ASCII alternatives
   - Use standard tmux color names

3. **New states** should:
   - Be clearly distinguishable
   - Have obvious visual indicators
   - Be documented with examples

## Documentation

When updating documentation:

- Keep README concise and scannable
- Use examples liberally
- Include screenshots/examples for visual features
- Update CHANGELOG.md for user-facing changes
- Keep examples/tmux.conf.example up to date

## Questions?

Feel free to open an issue for any questions about contributing!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
