# setup

Dotfiles and other configurations using `Nix`.

## NixOS

setup: `sudo nixos-rebuild switch --flake /home/soft/setup`

then can do `sudo nixos-rebuild switch`

## nix-darwin

setup:
`sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake /Users/soft/setup#aaron`

then can do `sudo darwin-rebuild switch`
