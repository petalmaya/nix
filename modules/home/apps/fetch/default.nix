{ pkgs, lib, config, ... }:
{
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    programs.fastfetch = {
      enable = true;
    };
    
    xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;
  };
}
