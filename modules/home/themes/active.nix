# which theme is on right now, for modules that vary by theme (foot).
# NOTE: starship + fastfetch are NOT theme-gated anymore - matugen owns
# them on every theme (see modules/home/services/matugen). Don't add
# theme checks for those; toggle nixtop.services.matugen.{starship,fastfetch}.enable instead.
{ config, lib, ... }:
let
  t = config.nixtop.themes;
in {
  options.nixtop.activeTheme = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum [
      "nagare"
      "manguru"
      "teakettler"
      "noctaniri"
      "redpine"
      "rosepine-dark"
    ]);
    internal = true;
    readOnly = true;
    default =
      if t.nagare.enable then "nagare"
      else if t.manguru.enable then "manguru"
      else if t.teakettler.enable then "teakettler"
      else if t.noctaniri.enable then "noctaniri"
      else if t.redpine.enable then "redpine"
      else if t.rosepine-dark.enable then "rosepine-dark"
      else null;
  };
}
