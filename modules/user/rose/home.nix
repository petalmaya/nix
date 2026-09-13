{ config, pkgs, ... }:
{
  imports = [ ./nixpak.nix ];

  home.username = "rose";
  home.homeDirectory = "/home/rose";

  nixtop = {
    terminal.zsh.enable = true;
    terminal.tmux.enable = true;
    terminal.foot.enable = true;
    apps.fetch.enable = true;
    apps.yazi.enable = true;
    apps.firefox-esr.enable = true;
    apps.emacs.enable = true;
  };

  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";

  home.packages = [ pkgs.git ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    templates = "${config.home.homeDirectory}/Templates";
    setSessionVariables = true;
  };
}
