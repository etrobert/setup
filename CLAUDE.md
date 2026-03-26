# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

This is a personal dotfiles and system configuration repository using Nix for
managing configurations.

There are nix-darwin and NixOS configurations.

## Architecture

### Stow-based Configuration Management

- Each top-level directory represents a tool's configuration
- The architecture of each of these directory represents the architecture from
  root of home directory (like a `stow` directory).

### Development Environment

- Neovim with Lua configuration and nightly `vim.pack` package manager
- Git configuration with custom completion and prompt integration
