# setup

Dotfiles and other configurations using
[stow](https://linux.die.net/man/8/stow).

See `./setup.sh`.

## Zen Browser

Set `zen.theme.content-element-separation` from 8 to 4. Set
`zen.theme.border-radius` from 10 to 12.

## Nix

### NixOS

setup: `sudo nixos-rebuild switch --flake /home/soft/setup/nix`

then can do `sudo nixos-rebuild switch`

### nix-darwin

setup: `ln /Users/soft/setup/nix /etc/nix-darwin`

then can do `sudo darwin-rebuild switch`
