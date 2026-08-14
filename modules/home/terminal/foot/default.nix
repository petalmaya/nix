{ pkgs, lib, config, inputs, ... }:
let
  theme = config.nixtop.activeTheme;

  # One branch per theme that wants its own foot config; anything not
  # listed here (redpine, rosepine-dark, noctaniri, or no theme at all)
  # falls through to `default`. Nix has no native switch/case - this
  # `cases` attrset (dispatched below via `active`) is the idiomatic
  # equivalent, keyed off `nixtop.activeTheme`
  # (modules/home/themes/active.nix) instead of a bespoke per-module
  # boolean check. Adding a 5th theme's own foot config later is one more
  # branch here, not a rewritten condition.
  cases = {
    kurukuru = {
      configFile = {
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
        # file below instead, same pattern already used for the default
        # branch's own theme file.
        "foot/themes/noctalia".source = "${inputs.self}/assets/dots/kurukuru/foot/themes/noctalia";
      };
      # dotsquick's foot.ini `include`s "themes/flutterice", which matugen
      # (re)writes on every theme run - see comment above. Seed a real,
      # writable copy of the vendored committed version so the include
      # doesn't error out before the first matugen run has happened; once
      # matugen runs, it overwrites this with live colors and home-manager
      # never touches it again (not managed here).
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/flutterice" ] || $DRY_RUN_CMD cp "${inputs.self}/assets/dots/kurukuru/foot/themes/flutterice" "$HOME/.config/foot/themes/flutterice"
      '';
    };

    # Not a real theme case, just this repo's own foot.ini fallback -
    # covers null (no theme enabled) and every theme without a bespoke
    # foot config of its own (redpine, rosepine-dark, noctaniri).
    default = {
      configFile."foot/foot.ini".source = ./foot.ini;
      # Only relevant to this repo's own noctaniri-flavoured foot.ini,
      # which `include`s an empty theme file Noctalia is expected to fill
      # in later.
      activation = ''
        $DRY_RUN_CMD mkdir -p $HOME/.config/foot/themes
        $DRY_RUN_CMD [ -e "$HOME/.config/foot/themes/noctalia" ] || touch "$HOME/.config/foot/themes/noctalia"
      '';
    };
  };

  # `theme` may be null (no theme enabled) - `cases.${null}` isn't valid
  # attribute access, so guard it explicitly rather than relying on `or`
  # to catch that case too.
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
