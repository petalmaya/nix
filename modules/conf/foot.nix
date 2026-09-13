{ config, lib, pkgs, ... }:
let
  # generated colors file lives at a runtime path, not inside the repo checkout.
  # Either matugen or noctalia writes it; foot's declarative config just includes it.
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
          alpha = "0.8";
        };
      };
    };

    # ensure the include doesn't error before the first theme generation
    home.activation.ensureFootGenerated = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$(dirname "${generatedPath}")"
      $DRY_RUN_CMD [ -e "${generatedPath}" ] || $DRY_RUN_CMD touch "${generatedPath}"
    '';
  };
}
