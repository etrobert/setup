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
          extra-substituters = [
            "https://nix-community.cachix.org"
            "https://soft-nix.cachix.org"
          ];
          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "soft-nix.cachix.org-1:/e6Y6fH2WAyIFK+F7+8bXTF4KdO4eRa4ed/d46Ytrxs="
          ];
          auto-optimise-store = true;
          download-buffer-size = 134217728; # 128 MiB
        };

        environment.systemPackages =
          (with self.packages.${pkgs.stdenv.hostPlatform.system}; [
            bash-wrapped
            git-wrapped
            tmux-wrapped
            tmux-sessionizer
            switch
          ])
          ++ (with pkgs; [
            bat
            coreutils
            entr
            eza
            fd
            fzf
            htop
            jq
            magic-wormhole
            ripgrep
            wget
          ]);

        age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

        programs = {
          ssh.extraConfig = ''
            Host *
              ServerAliveInterval 10
              ServerAliveCountMax 3
              ControlMaster auto
              ControlPersist 3600
              ControlPath ~/.ssh/ctrl-%r@%h:%p
              ForwardAgent yes
              AddKeysToAgent yes
          '';

          ssh.knownHosts = {
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
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvejXYLtulpvy+h311SuQVlpQhaNBh7LO5zGbazd2bh";
            };
          };

          zsh = {
            enable = true;
            # Disable system compinit; we call compinit -u in .zshrc to skip
            # insecure directory warnings caused by Nix store paths.
            enableGlobalCompInit = false;
          };
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
