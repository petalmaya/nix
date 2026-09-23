{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Runtime path; matugen or noctalia writes it, foot only includes it.
  generatedPath = "${config.xdg.configHome}/foot/themes/generated";
in
{
  options.nixtop.terminal.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf config.nixtop.terminal.foot.enable {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:size=11";
          pad = "12x12";
          shell = "${pkgs.zsh}/bin/zsh";
          include = generatedPath;
        };
        colors-dark = {
          alpha = "0.7";
        };
      };
    };

    # Seeded empty so the include never fails before first theme generation.
    home.activation.ensureFootGenerated = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$(dirname "${generatedPath}")"
      $DRY_RUN_CMD [ -e "${generatedPath}" ] || $DRY_RUN_CMD touch "${generatedPath}"
    '';
  };
}
