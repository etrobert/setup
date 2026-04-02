_: {
  flake = rec {
    nixosModules.base =
      { self, pkgs, ... }:
      {
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          extra-substituters = [ "https://nix-community.cachix.org" ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          trusted-users = [
            "root"
            "@wheel" # nixos
            "@admin" # darwin
          ];
          auto-optimise-store = true;
          download-buffer-size = 134217728; # 128 MiB
        };

        nix.gc = {
          automatic = true;
          options = "--delete-older-than 10d";
        };

        environment.systemPackages =
          (with self.packages.${pkgs.stdenv.hostPlatform.system}; [
            git-wrapped
            tmux-wrapped
            tmux-sessionizer
            switch
          ])
          ++ (with pkgs; [
            bat
            btop
            coreutils
            difftastic
            entr
            eza
            fd
            fzf
            gh
            htop
            jq
            magic-wormhole
            ripgrep
            shellcheck
            stow
            unzip
            vim
            wget
            zsh-autosuggestions # Fish shell autosuggestions for Zsh
            zsh-syntax-highlighting
          ]);

        age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

        programs.ssh.knownHosts = {
          pi = {
            hostNames = [ "pi" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbTCtRJeFqky1PSKe45KI0aMhpKqgd32Z9Fy9S4Op89";
          };
          tower = {
            hostNames = [ "tower" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHagaONxn4Ua5dkPfiGuavydHFfIEUVWMBrZHsucIILT";
          };
          aaron = {
            hostNames = [ "aaron" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/Y38NV8a/9rfDq+7W1UFfAFDo8SkwQ5JAl/U24u0ne";
          };
        };

        programs.zsh = {
          enable = true;
          # Disable system compinit; we call compinit -u in .zshrc to skip
          # insecure directory warnings caused by Nix store paths.
          enableGlobalCompInit = false;
        };

        users.users.soft.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILB4WoJruElpVJyHuniZ+NO2NZXjh2gzklJAAShCzrgi soft@aaron.local"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiLGjBlPoqRSzJ7KfEyMzJ3JRBqelOepsiL4ri9OqW soft@leod"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILe8/rx4MPrvwQBU1cy5qkhBgnRALS6Jzc9I20EcBnAx soft@nixos"
        ];
      };

    darwinModules.base = nixosModules.base;
  };
}
