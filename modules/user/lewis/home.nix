{ config, pkgs, ... }:
{
  home.username = "lewis";
  home.homeDirectory = "/home/lewis";

  nixtop = {
    terminal.zsh.enable = true;
    terminal.tmux.enable = true;
    terminal.foot.enable = true;
    apps.fetch.enable = true;
    apps.yazi.enable = true;
    apps.firefox-esr.enable = true;
  };

  home.packages = [ pkgs.git ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
  };
}
