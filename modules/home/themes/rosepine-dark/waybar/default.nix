{ config, lib, pkgs, ... }:

lib.mkIf config.nixtop.themes.rosepine-dark.enable {
  home.packages = with pkgs; [
    waybar
    playerctl
    htop
    s-tui
    gdu
  ];

  xdg.configFile = {
    "waybar/config.jsonc".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
  };
}
