# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

Personal dotfiles and system configuration repository using Nix flakes, managing
multiple machines: macOS (`aaron`) and Linux workstations (`tower`, `leod`) and
a Raspberry Pi (`pi`).

## Rebuild Commands

```sh
# NixOS
sudo nixos-rebuild switch --flake /home/soft/setup/nix

# macOS (nix-darwin)
sudo darwin-rebuild switch --flake /Users/soft/setup/nix
```

## Architecture

### Configuration Layout

Program configs live colocated with their wrapper in `nix/pkgs/`. Each
`*-wrapped` package embeds its config directly and is self-contained.

The top-level stow-style directories (e.g. `nvim/`, `ghostty/`) are deprecated
and being migrated to this wrapper pattern.

### Nix Flake Structure (`nix/`)

**`flake.nix`** uses flake-parts. Key inputs: nixpkgs (unstable), nix-darwin,
agenix (secrets).

**Hosts** (`nix/modules/hosts/`): one directory per machine. Each has
`default.nix` (flake module), `configuration.nix` (host settings), and
`hardware-configuration.nix` (Linux only).

**Shared modules** (`nix/modules/`):

- `base.nix` — common system config (nix settings, SSH keys, zsh, packages)
  applied to all hosts
- `workstation.nix` — dev tools and GUI apps (claude-code, VS Code, node, go,
  etc.)
- `nixos-base.nix` — NixOS system baseline
- `nixos-workstation.nix` — NixOS desktop: Niri compositor, GDM, Waybar, audio,
  bluetooth

**Custom packages** (`nix/pkgs/`): wrapped tool configurations (neovim-wrapped,
zsh-wrapped, tmux-wrapped, waybar-wrapped, etc.) and custom scripts
(gen-commit-msg, tmux-sessionizer, pm, brightness-control, etc.).

**Secrets** (`nix/secrets/`): agenix-encrypted secrets (tailscale authkey,
openai-api-key, gemini-api-key).

### Caches

Personal Cachix: `soft-nix.cachix.org`. Also uses `nix-community.cachix.org`.

### macOS-specific (`aaron`)

- skhd hotkeys: `Alt+HJKL` → arrow keys, `Alt+[1-9]` → app launch
- Caps Lock remapped to Control via launchd daemon
- Touch ID for sudo
- Dock apps defined in `nix/modules/hosts/aaron/dock-apps.nix`

### Linux-specific

- Niri (Wayland compositor, dev channel) with Waybar status bar
- DDC/CI backlight and brightness control

### Development Environment

- Neovim with Lua config in `nix/pkgs/neovim-wrapped/`, plugins managed via Nix
- Git with custom scripts: `gen-commit-msg`, `git-find-commit`,
  `tmux-sessionizer`
- Shell: zsh; terminal: Ghostty
