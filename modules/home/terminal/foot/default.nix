{ pkgs, lib, config, inputs, ... }:
let
  theme = config.nixtop.activeTheme;

  # per-theme foot config, falls through to default for themes without one
  cases = {
    nagare = {
      configFile = {
        "foot/foot.ini".source = "${inputs.self}/modules/home/themes/nagare/foot/foot.ini";
        "foot/colors.ini".source = "${inputs.self}/modules/home/themes/nagare/foot/colors.ini";
        # themes/pinaceae is matugen's output, managed below instead
        "foot/themes/noctalia".source = "${inputs.self}/modules/home/themes/nagare/foot/themes/noctalia";
      };
      # seed a writable copy so the include doesn't error before matugen's
      # first run; matugen owns the file after that
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/pinaceae" ] || $DRY_RUN_CMD cp "${inputs.self}/modules/home/themes/nagare/foot/themes/pinaceae" "$HOME/.config/foot/themes/pinaceae"
      '';
    };

    # same foot theme as nagare, just under mango instead of niri - the
    # look isn't changing, so this reuses nagare's files rather than
    # forking a copy
    manguru = {
      configFile = {
        "foot/foot.ini".source = "${inputs.self}/modules/home/themes/nagare/foot/foot.ini";
        "foot/colors.ini".source = "${inputs.self}/modules/home/themes/nagare/foot/colors.ini";
        "foot/themes/noctalia".source = "${inputs.self}/modules/home/themes/nagare/foot/themes/noctalia";
      };
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/pinaceae" ] || $DRY_RUN_CMD cp "${inputs.self}/modules/home/themes/nagare/foot/themes/pinaceae" "$HOME/.config/foot/themes/pinaceae"
      '';
    };

    # teakettler's own foot look: foot.ini + colors.ini are out-of-store
    # symlinks so edits are live, and themes/pinaceae is matugen's output
    # (seeded writable from the committed copy below, matugen owns it after
    # that) - same scheme as nagare/manguru, so the colours follow the
    # wallpaper instead of being frozen in the store.
    teakettler = {
      configFile = {
        "foot/foot.ini".source =
          config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/foot/foot.ini";
        "foot/colors.ini".source =
          config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.teakettler.repoPath}/modules/home/themes/teakettler/foot/colors.ini";
      };
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/pinaceae" ] || $DRY_RUN_CMD cp "${inputs.self}/modules/home/themes/teakettler/foot/themes/pinaceae" "$HOME/.config/foot/themes/pinaceae"
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
# Matugen theme source lives here too: foot.temp + foot-apply.sh
# (toggle: nixtop.services.matugen.templates.foot.enable).
