_: {
  flake.nixosModules.postgresql-read-access = _: {
    services.postgresql.ensureUsers = [ { name = "soft"; } ];
    # ensureClauses cannot grant role membership
    systemd.services.postgresql-setup.postStart = ''
      psql --tuples-only --no-align --command 'GRANT pg_read_all_data TO soft'
    '';
  };
}
