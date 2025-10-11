# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

This is a personal dotfiles and system configuration repository using GNU Stow
for managing symlinked configurations. Each folder contains configuration for a
specific tool or application.

## Key Commands

### Setup and Installation

- `./setup.sh` - Complete system setup script that installs Homebrew, dotfiles,
  and configures macOS
- `brew bundle install` - Install all Homebrew packages and applications
- `stow <folder>` - Symlink configuration from a specific folder to home
  directory

### Custom Utilities

Several custom scripts are available in `*/bin/` directories:

- `tmux/bin/tmux-sessionizer` - tmux session management utility
- `git/bin/gen-commit-msg` - Generate commit messages
- `macos/bin/*` - Various macOS utilities (dock speed, DNS flush, window resize,
  etc.)

### Development Tools

- Neovim configuration is in `nvim/.config/nvim/` with Lazy.nvim package manager
- VS Code extensions and settings are managed via Brewfile and `vscode/`
  directory
- Bash configuration includes custom PS1 with git status and command timing

## Architecture

### Stow-based Configuration Management

- Each top-level directory represents a tool's configuration
- Stow creates symlinks from these directories to the appropriate locations in
  `$HOME`
- Configuration files maintain their expected paths (e.g.,
  `nvim/.config/nvim/init.lua`)

### Shell Environment

- Uses Bash as default shell with extensive customization in `bash/.bashrc`
- Custom PS1 with git status, command timing, and exit codes
- Aliases are split across platform-specific files (`.alias.darwin`,
  `.alias.linux`)

### System Integration

- macOS-specific setup including dock configuration, trackpad settings, and
  keyboard remapping
- LaunchAgent for Caps Lock → Control remapping
- skhd for hotkey management
- Homebrew for package management including development tools and applications

### Development Environment

- Neovim with Lua configuration and Lazy.nvim
- Node.js via nvm with automatic latest version installation
- Git configuration with custom completion and prompt integration
- Development tools: Go, Rust, Bun, various CLI utilities

## Important Notes

- Font dependencies: Fira Code and Fira Code Nerd Font required
- SSH key generation and GitHub CLI authentication handled by setup script
- Some configurations require manual steps (Firefox profile setup, VS Code first
  launch)
- Setup script is idempotent and can be run multiple times safely
