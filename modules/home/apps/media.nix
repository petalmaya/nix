{ config, lib, pkgs, unstable-pkgs, ... }:

let
  cfg = config.nixtop.apps.media;
  packages = {
    "rmpc" = pkgs.rmpc;
    tauon = unstable-pkgs.tauon;
    cava = pkgs.cava;
    ffmpeg = pkgs.ffmpeg;
    ffmpegthumbnailer = pkgs.ffmpegthumbnailer;
    feh = pkgs.feh;
    loupe = pkgs.loupe;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.media = {
    enable = lib.mkEnableOption "Media players and media tools";
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Package names to leave out of this group.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.attrValues selectedPackages;
  };
}
