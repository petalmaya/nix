{ config, lib, pkgs, ... }:
let
  matugenOwnsFastfetch =
    (config.nixtop.services.matugen.enable or false)
    && (config.nixtop.services.matugen.templates.fastfetch.enable or false);
in
{
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    home.packages = [ pkgs.hyfetch ];

    programs.fastfetch = {
      enable = true;
      settings = lib.mkIf (!matugenOwnsFastfetch) {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        modules = [
          "title"
          "separator"
          "os"
          "kernel"
          "uptime"
          "shell"
          "de"
          "wm"
          "wmtheme"
          "theme"
          "icons"
          "font"
          "cursor"
          "terminal"
          "break"
        ];
      };
    };
  };
}
