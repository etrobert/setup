# Wraps ZapZap (WhatsApp Web client) to enable QtWebEngine's PipeWire screen
# capturer, without which screen sharing in calls finds no screens on Wayland
# ("Screen capturing is not available. Media list will be empty.").
# --set-default, so ad-hoc QTWEBENGINE_CHROMIUM_FLAGS overrides still win;
# zapzap itself appends its own flags to this variable at startup.
{
  zapzap,
  wrapPackage,
}:
wrapPackage {
  package = zapzap;
  setDefaults.QTWEBENGINE_CHROMIUM_FLAGS = "--enable-features=WebRTCPipeWireCapturer";
}
