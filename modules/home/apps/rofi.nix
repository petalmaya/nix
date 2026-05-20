{ config, pkgs, lib, ... }:

{
  options.nixtop.apps.rofi.enable = lib.mkEnableOption "Rofi configuration";

  config = lib.mkIf config.nixtop.apps.rofi.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      theme = ../../../assets/dots/everforest.rasi;
    };
  };
}
