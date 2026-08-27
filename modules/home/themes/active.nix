# which theme is on right now, for modules that vary by theme
{ config, lib, ... }:
let
  t = config.nixtop.themes;
in {
  options.nixtop.activeTheme = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "kurukuru"
      "manguru"
      "noctaniri"
      "redpine"
      "rosepine-dark"
    ]);
    internal = true;
    readOnly = true;
    default =
      if t.kurukuru.enable then "kurukuru"
      else if t.manguru.enable then "manguru"
      else if t.noctaniri.enable then "noctaniri"
      else if t.redpine.enable then "redpine"
      else if t.rosepine-dark.enable then "rosepine-dark"
      else null;
  };
}
