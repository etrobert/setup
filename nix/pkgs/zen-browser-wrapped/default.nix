{ inputs', wrapFirefox }:
wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
  extraPolicies = {
    DontCheckDefaultBrowser = true;
    SearchEngines = {
      Default = "DuckDuckGo";
    };
  };
}
