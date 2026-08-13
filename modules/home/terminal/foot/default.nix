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
        # NOT "foot/themes" as a whole recursive dir - "themes/flutterice"
        # is matugen's own live *output* (programs.matugen.templates.foot
        # in ../../themes/kurukuru/default.nix writes
        # ~/.config/foot/themes/flutterice on every re-theme). A recursive
        # xdg.configFile symlinks every file in the dir individually
        # straight into the read-only Nix store, so matugen's post_hook
        # writeback to that one path was failing ("file is Read-Only, not
        # writing to it"). Only "themes/noctalia" (an inert leftover,
        # nothing ever writes to it on this branch) is safe to manage this
        # way - "themes/flutterice" gets a real, writable, copy-if-missing
        # file below instead, same pattern already used just below for
        # the noctaniri branch's own theme file.
        "foot/themes/noctalia".source = "${inputs.self}/assets/dots/kurukuru/foot/themes/noctalia";
      })
      (lib.mkIf (!useDotsquickFoot) {
        "foot/foot.ini".source = ./foot.ini;
      })
    ];

    # Only relevant to this repo's own noctaniri-flavoured foot.ini, which
    # `include`s an empty theme file Noctalia is expected to fill in later.
    home.activation.ensureFootNoctaliaTheme = lib.mkIf (!useDotsquickFoot) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/noctalia" ] || touch "$HOME/.config/foot/themes/noctalia"
      ''
    );

    # dotsquick's foot.ini `include`s "themes/flutterice", which matugen
    # (re)writes on every theme run - see comment above. Seed a real,
    # writable copy of the vendored committed version so the include
    # doesn't error out before the first matugen run has happened; once
    # matugen runs, it overwrites this with live colors and home-manager
    # never touches it again (not managed above).
    home.activation.ensureFootFlutterice = lib.mkIf useDotsquickFoot (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/flutterice" ] || $DRY_RUN_CMD cp "${inputs.self}/assets/dots/kurukuru/foot/themes/flutterice" "$HOME/.config/foot/themes/flutterice"
      ''
    );
  };
}
