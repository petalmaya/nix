{ pkgs, ... }:

{
  home.packages = with pkgs; [
    waybar
    playerctl
  ];

  xdg.configFile = {
    "waybar/config".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
    "waybar/colors.css".source = ./colors.css;
  };
}
