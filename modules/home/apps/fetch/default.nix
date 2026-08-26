{ pkgs, lib, config, ... }:
{
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    programs.fastfetch = {
      enable = true;
    };
    
    # matugen owns this file on kurukuru hosts
    xdg.configFile."fastfetch/config.jsonc" = lib.mkIf (!(config.nixtop.themes.kurukuru.enable or false)) {
      source = ./config.jsonc;
    };
  };
}
