# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

This is a personal dotfiles and system configuration repository using GNU Stow
for managing symlinked configurations. Each folder contains configuration for a
specific tool or application.

This repository used to be used to configure Mac and Arch Linux machines through
the `setup.sh` script found in `setup/`. Today, it is used to configure Mac and
NixOS through Nix (in `nix/`).

## Architecture

### Stow-based Configuration Management

- Each top-level directory represents a tool's configuration
- Stow creates symlinks from these directories to the appropriate locations in
  `$HOME`
- Configuration files maintain their expected paths (e.g.,
  `nvim/.config/nvim/init.lua`)

### Shell Environment

- Uses Bash as default shell with extensive customization in `bash/.bashrc`
- Custom Rust based prompt (`git@github.com:etrobert/pronto`) 1 with git status,
  command timing, and exit codes
- Aliases are split across platform-specific files (`.alias.darwin`,
  `.alias.linux`)

### MacOS System Integration

- macOS-specific setup including dock configuration, trackpad settings, and
  keyboard remapping
- LaunchAgent for Caps Lock → Control remapping
- skhd for hotkey management
- Homebrew for package management including development tools and applications

### Development Environment

- Neovim with Lua configuration and Lazy.nvim
- Git configuration with custom completion and prompt integration
- Development tools: Go, Rust, Bun, various CLI utilities

## Important Notes

- Font dependencies: Fira Code and Fira Code Nerd Font required
- SSH key generation and GitHub CLI authentication handled by setup script
- Some configurations require manual steps (Firefox profile setup, VS Code first
  launch)
- Setup script is idempotent and can be run multiple times safely
