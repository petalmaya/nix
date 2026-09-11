{ config, lib, ... }:

{
  options.nixtop.apps.yazi.enable = lib.mkEnableOption "Yazi file manager";

  config = lib.mkIf config.nixtop.apps.yazi.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
# The matugen theme template lives under services/matugen/templates.
# Toggle: nixtop.services.matugen.templates.yazi.enable.
