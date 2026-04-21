{
  symlinkJoin,
  makeWrapper,
  mako,
  writeText,
}:
let
  config = writeText "config" /* ini */ ''
    font=monospace 12
    margin=20
    default-timeout=5000
    border-radius=6
    background-color=#24273a
    border-color=#cdd6f4

    # Firefox/Zen request timeout=0 (never expire) for notifications like Google Calendar.
    # Override this to use our default-timeout instead.
    [app-name=Firefox]
    ignore-timeout=1

    [app-name="Zen"]
    ignore-timeout=1
  '';
in
symlinkJoin {
  name = "mako-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ mako ];
  meta.mainProgram = "mako";
  postBuild = ''
    wrapProgram $out/bin/mako \
      --add-flags "--config ${config}"

    rm $out/share/dbus-1/services/fr.emersion.mako.service
    cp ${mako}/share/dbus-1/services/fr.emersion.mako.service \
      $out/share/dbus-1/services/fr.emersion.mako.service
    substituteInPlace $out/share/dbus-1/services/fr.emersion.mako.service \
      --replace-fail "${mako}/bin/mako" "$out/bin/mako"

    rm $out/share/systemd/user/mako.service
    cp ${mako}/share/systemd/user/mako.service \
      $out/share/systemd/user/mako.service
    substituteInPlace $out/share/systemd/user/mako.service \
      --replace-fail "${mako}/bin/mako" "$out/bin/mako"
  '';
}
