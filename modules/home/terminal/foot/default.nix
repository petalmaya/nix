{ pkgs, lib, config, ... }:
{
  options.nixtop.terminal.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf config.nixtop.terminal.foot.enable {
    programs.foot = {
      enable = true;
    };

    xdg.configFile."foot/foot.ini".source = ./foot.ini;

    home.activation.ensureFootNoctaliaTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
      $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/noctalia" ] || touch "$HOME/.config/foot/themes/noctalia"
    '';
  };
}
