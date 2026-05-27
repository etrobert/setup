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

**Home router:** Vodafone Station Arris CGA6444VF (`192.168.0.1`). WAN IP:
`91.64.99.245`. No NAT hairpin. DHCP is disabled (pi handles it). Ports 80/443
are port-forwarded to tower (`.130`). The router **blocks LAN→LAN traffic on
port-forwarded ports** — WiFi clients cannot reach tower:80/443 directly.

**LAN DHCP + DNS:** served by `pi` via `dnsmasq` (`modules/lan-dns.nix`,
listening on `end0`, static `.18`). Pi auto-upgrades from main nightly — test
before merging.

**Static LAN addresses:** `pi end0` `.18` (MAC `DC:A6:32:13:51:14`), `tower`
`.130` (MAC `C8:4B:D6:CE:4E:78`).

**Split-horizon DNS targets:** `test/creatures/files/adele.etiennerobert.com`.
Dnsmasq overrides these to **`192.168.0.18` (pi)**, not tower directly, because
pi acts as a TCP proxy (DNAT 80/443 → tower). Direct `.130` doesn't work from
WiFi due to the port-forward block above.

**TCP proxy:** pi forwards ports 80/443 to tower via nftables DNAT + MASQUERADE.
WiFi clients hit pi (not blocked) → pi forwards to tower. Implemented in
`modules/lan-dns.nix` as an option on the `lanDns` module.

**IPv6:** The router sends RA with RDNSS pointing to its own GUA
`2a02:8109:8892:b700:14ea:8aff:febe:9cfd` (which proxies to Vodafone's upstream
DNS `2a02:8100:c0:241::4:1101`). This RDNSS **cannot be disabled** — the router
UI has no IPv6 configuration at all (ISP-locked). Pi has **no GUA IPv6** (only
ULA `fd00::18`). The router's IPv6 DHCP is disabled; pi's dnsmasq handles DHCP
only over IPv4.

**Vodafone Station API** (for future automation): model CGA6444VF, PHP-based
REST at `/api/v1/`. All calls require `X-Requested-With: XMLHttpRequest`. Login
is a two-step PBKDF2 flow — see session transcript for details.
`api/v1/session/ menu` is the authenticated entry point; `api/v1/login_conf` is
unauthenticated.

## GitHub

The `etrobert-bot` account used by Claude Code does not have admin rights on
this repo. Admin-level operations (branch protection, repo settings) require the
`etrobert` account — flag these to the user rather than attempting them.
