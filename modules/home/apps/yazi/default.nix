{ config, lib, ... }:

{
  options.nixtop.apps.yazi.enable = lib.mkEnableOption "Yazi file manager";

  config = lib.mkIf config.nixtop.apps.yazi.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
# Matugen theme source lives here too: yazi-theme.toml.temp
# (toggle: nixtop.services.matugen.templates.yazi.enable).
