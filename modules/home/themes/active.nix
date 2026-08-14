# Read-only "which theme is active" switch, derived from the themes'
# own independent `nixtop.themes.<name>.enable` flags - those stay exactly
# as they are (still toggled individually per host/user, still no
# enforced mutual exclusivity if you really do flip two on at once), this
# just gives theme-agnostic modules (terminal/foot, etc.) one place to ask
# "which theme, if any, is on right now" instead of each one hand-rolling
# its own `config.nixtop.themes.kurukuru.enable or false`-style check.
#
# Nix has no native switch/case; `lib.mkMerge` of per-branch `lib.mkIf`s
# (see terminal/foot/default.nix) is the idiomatic equivalent, keyed off
# this value.
{ config, lib, ... }:
let
  t = config.nixtop.themes;
in {
  options.nixtop.activeTheme = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "kurukuru"
      "noctaniri"
      "redpine"
      "rosepine-dark"
    ]);
    internal = true;
    readOnly = true;
    default =
      if t.kurukuru.enable then "kurukuru"
      else if t.noctaniri.enable then "noctaniri"
      else if t.redpine.enable then "redpine"
      else if t.rosepine-dark.enable then "rosepine-dark"
      else null;
    description = ''
      Which theme is currently active, for switch/case-style dispatch in
      modules that need to vary by theme but aren't themselves a theme
      module (e.g. terminal/foot). Derived from the theme modules' own
      `nixtop.themes.<name>.enable` options - not a separate toggle, and
      doesn't replace them. `null` if none (or, edge case, more than one)
      are enabled.
    '';
  };
}
