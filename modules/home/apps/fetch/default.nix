{ pkgs, lib, config, ... }:
{
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    programs.fastfetch = {
      enable = true;
    };
    
    # matugen owns this file on nagare/manguru hosts
    xdg.configFile."fastfetch/config.jsonc" = lib.mkIf (!(config.nixtop.themes.nagare.enable or false) && !(config.nixtop.themes.manguru.enable or false)) {
      source = ./config.jsonc;
    };
  };
}
