{ config, pkgs, lib, ... }:

{
  options.nixtop.services.mako.enable = lib.mkEnableOption "Mako notification daemon";

  config = lib.mkIf config.nixtop.services.mako.enable {
    services.mako = {
      enable = true;
      extraConfig = builtins.readFile ./config;
    };
  };
}
