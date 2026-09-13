{ config, lib, ... }:
{
  options.nixtop.apps.yazi.enable = lib.mkEnableOption "Yazi file manager";

  config = lib.mkIf config.nixtop.apps.yazi.enable {
    programs.yazi = {
      enable = true;
      # updated behavior for 26.05 (was "yy" before, now "y")
      shellWrapperName = "y";
    };
  };
}
