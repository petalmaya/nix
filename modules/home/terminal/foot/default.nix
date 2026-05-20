{ pkgs, lib, config, ... }:
{
  options.nixtop.terminal.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf config.nixtop.terminal.foot.enable {
    programs.foot = {
      enable = true;
    };

    xdg.configFile."foot/foot.ini".source = ./foot.ini;
  };
}
