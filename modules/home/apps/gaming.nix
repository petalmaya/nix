{ pkgs, lib, config, unstable-pkgs, ... }:

{
  options.nixtop.apps.gaming.enable = lib.mkEnableOption "Gaming applications";

  config = lib.mkIf config.nixtop.apps.gaming.enable {
    home.packages = with pkgs; [
      wine
      renpy
      obs-studio
      prismlauncher
      openttd
      openrct2
      bolt-launcher
      steam-run
      unstable-pkgs.vesktop
      pokemmo-installer
    ];
  };
}
