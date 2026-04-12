{ inputs', wrapFirefox }:
wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
  extraPolicies = {
    SearchEngines = {
      Default = "DuckDuckGo";
    };
  };
}
