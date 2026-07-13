{ config, pkgs, lib, inputs, ... }:

{
  home.username = "lewis";
  home.homeDirectory = "/home/lewis";

  # Enable desired modules via options
  nixtop = {
    themes.noctaniri.enable = true;
    terminal.foot.enable = true;
    # apps.floorp.enable = true;
    # apps.zen.enable = true;
    apps.firefox-esr.enable = true;
    services.flatpak.enable = true;
  };

  home.packages = with pkgs; [
    git
    fuzzel
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
  };
}
