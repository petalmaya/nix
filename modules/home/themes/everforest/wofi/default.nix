{ config, lib, pkgs, ... }:

lib.mkIf config.nixtop.themes.everforest.enable {
  xdg.configFile."wofi/style.css".source = ./style.css;
}
