_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.himalaya-wrapped =
        let
          address = "etiennerobert33@gmail.com";
          password = {
            # Run without a shell or PATH lookup, so the path must be absolute.
            command = [
              "${pkgs.coreutils}/bin/cat"
              "/run/agenix/gmail-app-password"
            ];
          };
          configFile = (pkgs.formats.toml { }).generate "himalaya.toml" {
            accounts.gmail = {
              default = true;
              email = address;
              display-name = "Étienne Robert";

              imap.server = "imaps://imap.gmail.com:993";
              imap.sasl.plain = {
                username = address;
                inherit password;
              };

              smtp.server = "smtps://smtp.gmail.com:465";
              smtp.sasl.plain = {
                username = address;
                inherit password;
              };

              # Gmail's SMTP already files sent mail in Sent; a copy would duplicate it.
              message.send.save-copy = false;

              mailbox.alias = {
                sent = "[Gmail]/Sent Mail";
                drafts = "[Gmail]/Drafts";
                trash = "[Gmail]/Trash";
                archive = "[Gmail]/All Mail";
              };
            };
          };
        in
        self'.legacyPackages.wrapPackage {
          package = pkgs.himalaya;
          flags = [ "-c ${configFile}" ];
        };
    };
}
