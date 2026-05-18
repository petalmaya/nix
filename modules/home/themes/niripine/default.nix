{ config, lib, ... }: {
  options.nixtop.themes.niripine.enable = lib.mkEnableOption "Niripine Theme";

  imports = [
    ./niri
    ./waybar
    ./wofi
  ];
}
