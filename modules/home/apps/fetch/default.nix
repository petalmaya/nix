{ pkgs, lib, config, ... }:
let
  # matugen owns fastfetch on ALL themes when its master + fastfetch
  # toggles are on - no per-theme allowlist anymore
  matugenOwnsFastfetch =
    (config.nixtop.services.matugen.enable or false)
    && (config.nixtop.services.matugen.templates.fastfetch.enable or false);
in {
  options.nixtop.apps.fetch.enable = lib.mkEnableOption "Fastfetch/Hyfetch tool";

  config = lib.mkIf config.nixtop.apps.fetch.enable {
    programs.fastfetch = {
      enable = true;
    };

    # static fallback only when matugen isn't owning the file
    xdg.configFile."fastfetch/config.jsonc" = lib.mkIf (!matugenOwnsFastfetch) {
      source = ./config.jsonc;
    };
  };
}
# The matugen template lives under services/matugen/templates/fastfetch.
# Toggle: nixtop.services.matugen.templates.fastfetch.enable.
