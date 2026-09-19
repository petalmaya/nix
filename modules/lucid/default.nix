# Lucid — Material-3 Quickshell shell (upstream: Sn3akyy1/lucid, MIT).
# Tracked as the `lucid` flake input (see UPSTREAM); the shell tree is never
# vendored here, so `nix flake lock --update-input lucid` pulls upstream and
# only the layers below (mango binds, foot-over-kitty, matugen twins, seeds)
# can conflict. README.md lists what is Hyprland-only and degrades on mango.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  # Per-user shell (modules/shell): host default, overridable per user.
  shell = config.nixtop.shell;
  shellEnabled = shell == "lucid";
  cfg = config.nixtop.lucid;
  lucidSrc = inputs.lucid;

  lucidPkg = pkgs.callPackage ./package.nix { };

  # State the shell persists inside its own tree (install.sh seed list).
  # The rsync refresh skips these, so an upstream VERSION bump replaces QML
  # without eating settings, pins, reminders, or widget layout.
  stateFiles = [
    "lucidprefs/prefs.json"
    "lucidbar/blur.json"
    "lucidbar/clock_reminders.json"
    "lucidbar/mpris_shazam.json"
    "luciddocks/pinned.json"
    "luciddocks/usage.json"
    "luciddocks/wallpaper.json"
    "lucidmoji/config.json"
    "lucidmoji/state.json"
    "lucidkeys/state.json"
    "lucidwidgets/widgets.json"
  ];
  rsyncStateExcludes = lib.concatMapStringsSep " " (f: "--exclude '/${f}'") stateFiles;
in
{
  options.nixtop.lucid.enable = lib.mkOption {
    type = lib.types.bool;
    default = shellEnabled;
    description = "Enable the Lucid shell (quickshell). Follows nixtop.shell when auto.";
  };
  options.nixtop.lucid.compositor = lib.mkOption {
    type = lib.types.enum [
      "sway"
      "mango"
    ];
    default = "mango";
    description = ''
      Which compositor session Lucid runs in. "mango" is the ported target
      (modules/mango/variants/lucid/); "sway" leaves sway alone and relies on
      the mango session's own autostart, like noctalia's mango mode.
    '';
  };

  config = lib.mkIf (cfg.enable && shellEnabled) {
    home.packages = [
      lucidPkg
      pkgs.quickshell
      pkgs.jq
      pkgs.matugen
    ];

    # Theming twins: Lucid reads ~/.cache/quickshell/matugen.json (watched
    # live, so nixtop-theme recolors the shell) and ships its own starship
    # prompt. The base starship template must stand down (two writers rule).
    nixtop.services.matugen.templates.starship.enable = false;
    nixtop.services.matugen.templates.lucid-shell.enable = true;
    nixtop.services.matugen.templates.lucid-starship.enable = true;

    # Shell tree: writable copy (NOT a store symlink — Prefs persists state
    # inside it). Refresh on upstream VERSION change, preserving state files;
    # seed defaults (prefs minus the Hyprland-only workspaces module) + a
    # starter palette + cava config on first run. Mirrors install.sh.
    home.activation.ensureLucidShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SRC="${lucidSrc}"
      DST="$HOME/.config/quickshell"
      # a stale compat symlink (quickshell module era) would redirect the copy
      if [ -L "$DST" ]; then
        $DRY_RUN_CMD rm "$DST"
      fi
      if [ ! -f "$DST/VERSION" ] || [ "$(cat "$DST/VERSION" 2>/dev/null)" != "$(cat "$SRC/VERSION")" ]; then
        $DRY_RUN_CMD mkdir -p "$DST"
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete \
          --exclude '/support/' --exclude '/defaults/' --exclude '/wallpapers/' \
          --exclude '/install.sh' --exclude '/uninstall.sh' \
          --exclude '/README.md' --exclude '/LICENSE' --exclude '/CHANGELOG.md' \
          --exclude '/.github/' --exclude '/.gitignore' \
          ${rsyncStateExcludes} \
          "$SRC/" "$DST/"
      fi
      # state seeds — anything already in place wins (install.sh semantics)
      $DRY_RUN_CMD mkdir -p "$DST/lucidprefs" "$DST/lucidbar" "$DST/luciddocks" "$DST/lucidmoji" "$DST/lucidkeys" "$DST/lucidwidgets"
      seed() { # $1 = defaults basename, $2 = shell-tree relpath
        if [ ! -s "$DST/$2" ] && [ -f "$SRC/defaults/$1" ]; then
          $DRY_RUN_CMD cp "$SRC/defaults/$1" "$DST/$2"
        fi
      }
      # prefs seed carries the one mango tweak: the workspaces bar module is
      # Hyprland-only (Quickshell.Hyprland), so it starts off. jq keeps the
      # seed tracking upstream defaults instead of a checked-in copy.
      if [ ! -s "$DST/lucidprefs/prefs.json" ]; then
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.showWorkspaces = false' "$SRC/defaults/prefs.json" > "$DST/lucidprefs/prefs.json"
      fi
      seed blur.json lucidbar/blur.json
      seed clock_reminders.json lucidbar/clock_reminders.json
      seed mpris_shazam.json lucidbar/mpris_shazam.json
      seed pinned.json luciddocks/pinned.json
      seed usage.json luciddocks/usage.json
      seed wallpaper.json luciddocks/wallpaper.json
      seed moji-config.json lucidmoji/config.json
      seed moji-state.json lucidmoji/state.json
      seed keys-state.json lucidkeys/state.json
      seed widgets.json lucidwidgets/widgets.json
      # starter palette until the first nixtop-theme run (upstream: nord)
      $DRY_RUN_CMD mkdir -p "$HOME/.cache/quickshell"
      if [ ! -s "$HOME/.cache/quickshell/matugen.json" ]; then
        $DRY_RUN_CMD cp "$SRC/support/lucid/themes/nord/quickshell.json" "$HOME/.cache/quickshell/matugen.json"
      fi
      # cava visualiser config the bar strip parses (upstream support/cava)
      $DRY_RUN_CMD mkdir -p "$HOME/.config/cava"
      if [ ! -f "$HOME/.config/cava/quickshell.conf" ]; then
        $DRY_RUN_CMD cp "$SRC/support/cava/quickshell.conf" "$HOME/.config/cava/quickshell.conf"
      fi
    '';

    assertions = [
      {
        assertion = !(config.nixtop.noctalia.enable or false);
        message = "nixtop.shell selects one shell – cannot enable lucid with noctalia";
      }
      {
        assertion = !(config.nixtop.quickshell.enable or false);
        message = "nixtop.shell selects one shell – cannot enable lucid with quickshell";
      }
      {
        assertion = !(config.nixtop.jes.enable or false);
        message = "nixtop.shell selects one shell – cannot enable lucid with jes";
      }
      {
        assertion = cfg.compositor == "sway" || cfg.compositor == "mango";
        message = "nixtop.lucid.compositor must be mango (ported) or sway";
      }
    ];
  };
}
