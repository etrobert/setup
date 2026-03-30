{
  symlinkJoin,
  makeWrapper,
  mako,
}:
symlinkJoin {
  name = "mako-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ mako ];
  meta.mainProgram = "mako";
  postBuild = ''
    wrapProgram $out/bin/mako \
      --add-flags "--config ${./config}"

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
