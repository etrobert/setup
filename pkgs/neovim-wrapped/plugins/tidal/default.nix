{ pkgs, ... }:
let
  # vim-tidal is not in nixpkgs, so package it directly. Pinned to the latest
  # commit (the v1.x tags are old); it's a stable vimscript plugin.
  vim-tidal = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-tidal";
    version = "unstable-2023-06-02";

    src = pkgs.fetchFromGitHub {
      owner = "tidalcycles";
      repo = "vim-tidal";
      rev = "e440fe5bdfe07f805e21e6872099685d38e8b761";
      sha256 = "102j93zygjkrxgdxcsv4nqhnrfn1cbf4djrxlx5sly0bnvbs837j";
    };
  };
in
{
  plugins = [
    {
      plugin = vim-tidal;
      config = /* lua */ ''
        -- Live-code TidalCycles from .tidal files. The pattern language
        -- (GHCi + tidal) and the audio engine (SuperDirt) come from the
        -- project's `nix develop` (see the electronic-music flake), not from
        -- here -- this plugin only ships lines to a running GHCi.
        --
        -- tmux target: <localleader>-send pastes into a tmux pane running
        -- `tidal` (GHCi booted with Tidal). In tmux mode vim-tidal does not
        -- start GHCi itself, so launch `tidal` in its own pane first.
        vim.g.tidal_target = "tmux"
      '';
      extraPackages = with pkgs; [ tmux ];
    }
  ];
}
