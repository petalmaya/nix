{ config, pkgs, ... }:

{
  programs.wofi = {
    enable = true;
    style = builtins.readFile ./style.css;
    settings = {
      allow_images = true;
      allow_markup = true;
      term = "foot";
      width = 600;
      height = 400;
    };
  };
}
