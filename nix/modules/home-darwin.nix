{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.username = "soft";
  home.homeDirectory = "/Users/soft";

  home.file.".prettierrc".source = ../../prettier/.prettierrc;

  # Dotfiles managed outside the store (editable without rebuild)
  # home.file.".config/nvim".source =
  #   config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/nvim/.config/nvim";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
