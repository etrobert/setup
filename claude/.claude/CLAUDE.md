# Personal Development Environment - CLAUDE.md

This file provides context about my personal development setup, preferences, and workflows.

## Development Environment

### Shell & Terminal

- Primary shell: Bash with custom configuration
- Terminal: Ghostty
- tmux for session management with custom sessionizer script
- Custom PS1 with git status, command timing, and exit codes

### Editor & IDE

- Primary editor: Neovim with Lua configuration and Lazy.nvim

### Version Control Workflow

- Git with extensive custom aliases (use `git alias` to see all)
- Key aliases:
  - `git torelease` - Shows commits ready for release (origin/prod..origin/main)
  - `git release` - Deploys by pushing origin/main to prod
  - `git lg` - Pretty formatted log with graph
  - `git sco` - fzf branch checkout
  - `git sci` - Uses gen-commit-msg for commit messages

### Package Management

- Homebrew for system packages and applications
- nvm for node.js
- Development tools: Go, Rust, Bun

### Code Style Preferences

- JavaScript/TypeScript: ES modules, destructured imports

### Common Commands

- `./setup.sh` - Complete system setup script
- `brew bundle install` - Install all packages
- `stow <folder>` - Symlink configuration
- `tmux-sessionizer` - Quick tmux session management
- `git alias` - View all git aliases with descriptions

### Keyboard & Navigation

- Caps Lock mapped to Control
- skhd for hotkey management

### Important Notes

- Configuration uses GNU Stow for symlink management
- All configs maintain expected paths in home directory
- Setup script is idempotent and can be run multiple times

### Preferences

- Keep terminal output concise - prefer short, direct responses
- When working with files, always check existing patterns first
- Follow security best practices - never commit secrets
- Prefer editing existing files over creating new ones unless necessary

## Workflow Notes

- Always format files after editing
- Always typecheck and lint before committing
