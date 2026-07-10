# CLAUDE.md

## Repository Purpose

Personal dotfiles and system configuration repository using Nix flakes for:

- aaron: MacBook Pro M3 Pro 18GB RAM (macOS w/ nix-darwin)
- tower: AMD Ryzen 9700X Desktop — home server and workstation (NixOS)
- leod: Lenovo ThinkPad X1 Carbon 7th Gen (NixOS/Windows)
- pi: Raspberry Pi 4 Model B (Rev 1.1) (NixOS)

## Architecture

### Configuration Layout

Program configs live colocated with their wrapper in `pkgs/`. Each `*-wrapped`
package embeds its config directly and is self-contained. Home-manager should be
a last resort — prefer `-wrapped` packages and darwin/NixOS modules.

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

### Development Environment

- Window Manager (NixOS): Niri with Waybar
- Editor: Neovim, plugins managed via Nix
- Version Control: Git
- Session management: tmux, tmux-sessionizer script
- Shell: zsh
- Terminal: Ghostty

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

## Self-Cleaning Guards

When adding a temporary workaround that should be dropped once an upstream
condition changes (e.g. a `permittedInsecurePackages` entry, a version pin, a
patch), pair it with a guard that fails the build once the workaround stops
being load-bearing — don't rely on remembering to revisit it. Prefer this
whenever the "still needed?" condition can be expressed in Nix.

Example: the `electron-39.8.10` permit in `modules/workstation.nix` is paired
with an assertion that re-evaluates its consumer against a nixpkgs instance
without the permit (via `builtins.tryEval`); when the consumer no longer pulls
the insecure package, the assertion fails and prompts removal.

## LAN Networking

**Home router:** Vodafone Station Arris CGA6444VF (`192.168.0.1`). WAN IP:
`91.64.99.245`. No NAT hairpin. DHCP is disabled (pi handles it). Ports 80/443
are port-forwarded to tower (`.10`).

**LAN DHCP + DNS:** served by `pi` via `dnsmasq` (`modules/lan-dns.nix`,
listening on `end0`, static `.18`). Pi auto-upgrades from the `deploy` ref
(which CI fast-forwards to main once `all-builds` is green), converging within
minutes of a merge — test before merging.

**Static LAN addresses:** `pi end0` `.18` (MAC `DC:A6:32:13:51:14`), `tower`
`.10` (motherboard NIC `enp11s0`, static via NetworkManager in
`modules/hosts/tower/configuration.nix` — not a pi DHCP reservation). Tower's NM
profile uses pi (`.18`) for DNS so split-horizon resolution works on tower too.

**Testing the public/external path:** LAN clients resolve these names to tower
directly (split-horizon) and bypass the port-forward, so they can't exercise the
real external path. To test as an outside visitor would (public DNS →
`91.64.99.245` → port-forward → tower), move `aaron` onto the iPhone's cellular
hotspot — then `ssh aaron` and requests from it resolve to the public IP and
traverse the real path. Useful for end-to-end latency/throughput measurements.

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

## Notifications (ntfy)

`ntfy-wrapped` wraps the ntfy CLI with `NTFY_TOPIC=http://tower:2586/home`
pre-set. Use `ntfy publish "message"` to send a notification to all
workstations. Use `--delay 10m` (or `--at 8:30am`) to schedule delivery
server-side rather than sleeping locally.

## Home Assistant

HA runs on **`tower:8123`** (`modules/home-assistant.nix`). Access uses a
long-lived token: agenix secret `hass-token`, decrypted to
`/run/agenix/hass-token`. The `hass-cli-wrapped` package bakes in
`HASS_SERVER=http://100.103.91.42:8123` (tower's Tailscale IP, not the `tower`
hostname) and reads that token at runtime, and is on PATH for both the user's
shells and Claude Code. The IP is deliberate: `hass-cli` resolves names via
aiohttp/aiodns (c-ares), which ignores macOS scoped DNS / Tailscale MagicDNS, so
the `tower` hostname fails to resolve on `aaron`. `curl` (below) uses
`getaddrinfo`, so `tower:8123` is fine there.

**AirGradient ONE** (living room) entities are prefixed `sensor.i_9psl_*`. The
recorder keeps more than the dashboard shows — notably `sensor.i_9psl_pm0_3`
(0.3 µm particle _count_, the best fine-particle signal),
`sensor.i_9psl_voc_index`, and `sensor.i_9psl_nox_index`. The device's own local
API (`http://<ip>/measures/current`) returns only current values, no history.

## Planning future work

Plans are tracked as GitHub issues on `etrobert/setup`, not as local `.md`
files. Open an issue with the full plan body; reference it from PRs that
implement it.
