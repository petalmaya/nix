{ pkgs, ... }:

{
  home.packages = with pkgs; [
    waybar
    playerctl
    htop
    s-tui
    gdu
  ];

  xdg.configFile = {
    "waybar/config".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
  };
}
