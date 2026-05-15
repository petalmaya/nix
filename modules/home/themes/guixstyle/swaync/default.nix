{ config, lib, ... }:

lib.mkIf config.nixtop.themes.guixstyle.enable {
  xdg.configFile = {
    "swaync/config.json".source = ./config.json;
    "swaync/style.css".source = ./style.css;
  };
}
