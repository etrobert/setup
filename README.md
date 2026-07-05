# setup

Dotfiles and other configurations using `Nix`.

## NixOS

setup: `sudo nixos-rebuild switch --flake /home/soft/setup`

then can do `sudo nixos-rebuild switch`

## nix-darwin

setup:
`sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake /Users/soft/setup#aaron`

then can do `sudo darwin-rebuild switch`

### Manual steps

- **Download the premium "Zoe" voice** (System Settings → Accessibility → Spoken
  Content → System Voice → Manage Voices → English (US) → Zoe (Premium)). The
  config selects this voice as the system default for `say` (used by the
  `claude-speak` hook), but Apple ships no headless installer for the asset. If
  it isn't downloaded, `say` silently falls back to the default robotic voice.

## Nix in docker

Run nix commands in a docker container without installing Nix on your host
machine:

```sh
docker run -it -e NIX_CONFIG="experimental-features = nix-command flakes" nixos/nix nix run nixpkgs#hello
```
