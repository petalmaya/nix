{ pkgs, lib, config, inputs, ... }:
let
  # Kurukuru wants dotsquick's foot config instead of this repo's own -
  # rather than forking this whole module (foot itself, the
  # `programs.foot.enable` toggle, etc. stay identical either way), only
  # the config source branches on which theme is active. See
  # modules/home/themes/kurukuru for the other half of that swap (niri,
  # matugen).
  useDotsquickFoot = config.nixtop.themes.kurukuru.enable or false;
in
{
  options.nixtop.terminal.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf config.nixtop.terminal.foot.enable {
    programs.foot = {
      enable = true;
    };

    xdg.configFile = lib.mkMerge [
      (lib.mkIf useDotsquickFoot {
        "foot/foot.ini".source = "${inputs.self}/assets/dots/kurukuru/foot/foot.ini";
        "foot/colors.ini".source = "${inputs.self}/assets/dots/kurukuru/foot/colors.ini";
        "foot/themes" = {
          source = "${inputs.self}/assets/dots/kurukuru/foot/themes";
          recursive = true;
        };
      })
      (lib.mkIf (!useDotsquickFoot) {
        "foot/foot.ini".source = ./foot.ini;
      })
    ];

    # Only relevant to this repo's own noctaniri-flavoured foot.ini, which
    # `include`s an empty theme file Noctalia is expected to fill in later.
    # dotsquick's foot.ini instead includes its own committed
    # `themes/flutterice` (matugen output) + `colors.ini`, both real files
    # above already - nothing to touch-into-existence on that branch.
    home.activation.ensureFootNoctaliaTheme = lib.mkIf (!useDotsquickFoot) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/noctalia" ] || touch "$HOME/.config/foot/themes/noctalia"
      ''
    );
  };
}
