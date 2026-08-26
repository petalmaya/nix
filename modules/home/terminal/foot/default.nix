{ pkgs, lib, config, inputs, ... }:
let
  theme = config.nixtop.activeTheme;

  # per-theme foot config, falls through to default for themes without one
  cases = {
    kurukuru = {
      configFile = {
        "foot/foot.ini".source = "${inputs.self}/modules/home/themes/kurukuru/foot/foot.ini";
        "foot/colors.ini".source = "${inputs.self}/modules/home/themes/kurukuru/foot/colors.ini";
        # themes/flutterice is matugen's output, managed below instead
        "foot/themes/noctalia".source = "${inputs.self}/modules/home/themes/kurukuru/foot/themes/noctalia";
      };
      # seed a writable copy so the include doesn't error before matugen's
      # first run; matugen owns the file after that
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/flutterice" ] || $DRY_RUN_CMD cp "${inputs.self}/modules/home/themes/kurukuru/foot/themes/flutterice" "$HOME/.config/foot/themes/flutterice"
      '';
    };

    default = {
      configFile."foot/foot.ini".source = ./foot.ini;
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/noctalia" ] || touch "$HOME/.config/foot/themes/noctalia"
      '';
    };
  };

  active = if theme != null && cases ? ${theme} then cases.${theme} else cases.default;
in
{
  options.nixtop.terminal.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf config.nixtop.terminal.foot.enable {
    programs.foot = {
      enable = true;
    };

    xdg.configFile = active.configFile;

    home.activation.ensureFootTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] active.activation;
  };
}
