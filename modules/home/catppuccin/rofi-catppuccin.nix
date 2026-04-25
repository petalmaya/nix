{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = ../../assets/dots/catppuccin-mocha.rasi;
  };
}
