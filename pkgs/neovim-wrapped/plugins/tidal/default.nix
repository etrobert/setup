{ pkgs, ... }:
let
  # vim-tidal is not in nixpkgs, so package it directly. Pinned to the latest
  # commit (the v1.x tags are old); it's a stable vimscript plugin.
  vim-tidal = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-tidal";
    version = "1.4.8-unstable-2023-06-02";

    src = pkgs.fetchFromGitHub {
      owner = "tidalcycles";
      repo = "vim-tidal";
      rev = "e440fe5bdfe07f805e21e6872099685d38e8b761";
      hash = "sha256-8gyk17YLeKpLpz3LRtxiwbpsIbZka9bb63nK5/9IUoA=";
    };
  };
in
{
  plugins = [
    {
      plugin = vim-tidal;
      config = /* lua */ ''
        -- Ship .tidal lines to a tmux pane running `tidal` (GHCi+Tidal); it
        -- does not boot GHCi, so start `tidal` in its own pane first. The
        -- pattern language and SuperDirt engine come from the electronic-music
        -- flake's devShell, not from here.
        vim.g.tidal_target = "tmux"
      '';
      extraPackages = with pkgs; [ tmux ];
    }
  ];
}
