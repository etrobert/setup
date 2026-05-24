# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

Personal dotfiles and system configuration repository using Nix flakes, managing
multiple machines: macOS (`aaron`) and Linux workstations (`tower`, `leod`) and
a Raspberry Pi (`pi`).

## Architecture

### Configuration Layout

Program configs live colocated with their wrapper in `pkgs/`. Each `*-wrapped`
package embeds its config directly and is self-contained. Home-manager should be
a last resort — prefer `-wrapped` packages and darwin/nixos modules.

The `deprecated/` directory contains stow-style directories not yet migrated.

### Nix Flake Structure

**`flake.nix`** uses flake-parts. Key inputs: nixpkgs (unstable), nix-darwin,
agenix (secrets).

**Hosts** (`modules/hosts/`): one directory per machine. Each has `default.nix`
(flake module), `configuration.nix` (host settings), and
`hardware-configuration.nix` (Linux only).

**Shared modules** (`modules/`) — the core baseline:

- `base.nix` — common system config (nix settings, SSH keys, zsh, packages)
  applied to all hosts
- `workstation.nix` — dev tools and GUI apps (claude-code, VS Code, node, go,
  etc.)
- `nixos-base.nix` — NixOS system baseline
- `nixos-workstation.nix` — NixOS desktop: Niri compositor, GDM, Waybar, audio,
  Bluetooth

Opt-in feature modules expose `flake.nixosModules.<name>` and are imported
per-host as needed: `server.nix`, `home-assistant.nix`, `darkman.nix`,
`networkmanager.nix`, `pimsync.nix`, `lan-dns.nix`. Plumbing modules:
`darwinModules.nix` (darwin module-type plumbing), `unfree.nix`
(`allowedUnfreePackages` option), `nix-index.nix`. See `modules/` for the full
set.

**Custom packages** (`pkgs/`): wrapped tool configurations (neovim-wrapped,
zsh-wrapped, tmux-wrapped, waybar-wrapped, etc.) and custom scripts
(gen-commit-msg, tmux-sessionizer, pm, brightness-control, etc.).

Shell scripts are packaged with `writeShellApplication` with
`inheritPath = false` and explicit `runtimeInputs`.

**Secrets** (`secrets/`): agenix-encrypted secrets (Tailscale authkey, API keys,
Wi-Fi passwords, account passwords, etc.). See `secrets/secrets.nix` for the
authoritative list.

### Caches

Personal Cachix: `soft-nix.cachix.org`. Also uses `nix-community.cachix.org`.

### macOS specific (`aaron`)

- skhd hotkeys: `Alt+HJKL` → arrow keys, `Alt+[1-9]` → app launch
- Caps Lock remapped to Control via launchd daemon
- Touch ID for sudo
- Dock apps defined in `modules/hosts/aaron/dock-apps.nix`

### Linux specific

- Niri (Wayland compositor, dev channel) with Waybar status bar
- DDC/CI backlight and brightness control

### Development Environment

- Neovim with Lua config in `pkgs/neovim-wrapped/`, plugins managed via Nix
- Git with custom scripts: `gen-commit-msg`, `git-find-commit`,
  `tmux-sessionizer`
- Shell: zsh; terminal: Ghostty

### Testing wrapped package changes

The `*-wrapped` packages bake their config into the Nix store, so editing a
config file (e.g. a Neovim plugin's `config.lua`) does not affect the installed
binary until a system rebuild. To test a change in isolation, run just that
package from the flake — e.g. `nix run ".#neovim-wrapped" -- <file-or-dir>`.

### neovim-wrapped plugin conventions

Each plugin is a directory under `pkgs/neovim-wrapped/plugins/` with a
`default.nix`. Plugins are registered in `pkgs/neovim-wrapped/default.nix`.

**Existing catch-all plugins** — do not add unrelated code to these:

- `set` — vim options only (`vim.opt.*`, `vim.o.*`)
- `remap` — keymaps only (`vim.keymap.set`, `vim.api.nvim_create_user_command`)

New behavior (autocmds, etc.) belongs in its own dedicated plugin.

**Custom vs external plugins:**

- External: `plugin = pkgs.vimPlugins.foo;` with a `config` string calling
  `setup()`
- Custom (local Lua):
  `plugin = pkgs.vimUtils.buildVimPlugin { name = "..."; src = ./src; };`

**`config` field is optional** — omit it when the plugin sources itself via
`plugin/`.

## LAN Networking

**Home router:** Vodafone Station Arris TG3442DE (`192.168.0.1`) — **no NAT
reflection/hairpin**. LAN DHCP is toggled via IPv4 page → `Local DHCPv4 Server`
(currently OFF after PR2 cutover). The router cannot advertise a custom DNS via
DHCP.

**LAN DHCP + DNS:** served by `pi` via `dnsmasq` (`modules/lan-dns.nix`,
listening on `end0`, static `.18`). Split-horizon overrides only tower-hosted
subdomains (`test/creatures/files/adele.etiennerobert.com → 192.168.0.130`).
**Never wildcard the `etiennerobert.com` zone** — other subdomains live
elsewhere and must resolve publicly.

**Static LAN addresses:** `pi end0` `.18` (MAC `DC:A6:32:13:51:14`), `tower`
`.130` (MAC `C8:4B:D6:CE:4E:78`, also the 80/443 port-forward target on the
Station).

**Auto-upgrade:** `pi` rebuilds from `main` nightly — merging deploys to the
household DHCP/DNS server; test thoroughly before merging anything that touches
pi's network config.

## GitHub

The `etrobert-bot` account used by Claude Code does not have admin rights on
this repo. Admin-level operations (branch protection, repo settings) require the
`etrobert` account — flag these to the user rather than attempting them.
