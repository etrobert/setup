# Authenticates each machine against the sync server in atuin-server.nix.
#
# atuin keeps its session token in a sqlite meta store, so there is no way to
# hand a machine a session declaratively — only `atuin login` can mint one.
# This runs it at boot instead: already-authenticated machines short-circuit,
# so it is a no-op everywhere except a freshly installed one.
#
# A system unit rather than a user one, because ntfy-failure-alerts attaches
# OnFailure via /etc/systemd/system/service.d/ and never sees user units. A
# machine that silently stops syncing is the failure this is guarding against.
_: {
  flake.nixosModules.atuinLogin =
    {
      self,
      config,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) atuin-wrapped;
    in
    {
      age.secrets = {
        atuin-key = {
          file = ../../secrets/atuin-key.age;
          owner = "soft";
        };
        atuin-password = {
          file = ../../secrets/atuin-password.age;
          owner = "soft";
        };
      };

      systemd.services.atuin-login = {
        description = "Authenticate against the atuin sync server";

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = "soft";
          # atuin resolves its key and meta store relative to $HOME.
          Environment = "HOME=/home/soft";

          # --password on argv rather than stdin: omitting it makes atuin read
          # /dev/tty via rpassword and panic under systemd.
          ExecStart = pkgs.writeShellScript "atuin-login" ''
            exec ${atuin-wrapped}/bin/atuin login \
              --username soft \
              --password "$(cat ${config.age.secrets.atuin-password.path})" \
              --key "$(cat ${config.age.secrets.atuin-key.path})"
          '';
        };
      };
    };
}
