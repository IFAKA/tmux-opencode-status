# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-29

### Added
- **Intelligent caching system** for significant performance improvement
  - Content fingerprinting to detect unchanged panes
  - Configurable cache TTL (`@opencode_cache_ttl`)
  - Automatic cache cleanup for old files
- Performance configuration options
  - `@opencode_enable_cache` - toggle caching (default: true)
  - `@opencode_cache_ttl` - cache validity period (default: 5 seconds)

### Changed
- **Optimized state detection** - reduced from 100 to 20 lines analysis
- **Efficient grep patterns** - combined patterns, early exit on match
- **Reduced CPU usage** - skips analysis when pane content unchanged
- Improved README with performance documentation
- Updated recommended `status-interval` to 10 seconds (balanced)

### Performance
- ~80% reduction in CPU usage with multiple sessions
- Typical overhead: <10ms per update cycle (vs 50-100ms before)
- Cache hit rate: 70-90% in normal usage

## [1.0.0] - 2025-12-29

### Added
- Initial release
- Real-time OpenCode session monitoring in tmux status bar
- Four state detection: idle, busy, waiting, error
- Customizable icons and colors for each state
- Session count display
- Configurable separators and prefixes
- Support for both status-left and status-right placement
- Cross-platform support (macOS and Linux)
- Comprehensive documentation and examples

### Features
- Automatic detection of OpenCode/Claude Code processes
- Intelligent state analysis based on pane content
- Zero dependencies (pure Bash)
- TPM (Tmux Plugin Manager) support
- Manual installation support
