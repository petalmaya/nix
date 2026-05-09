{ config, lib, ... }: {
  options.nixtop.themes.everforest.enable = lib.mkEnableOption "Everforest Theme";

  imports = [
    ./sway
    ./waybar
    ./wofi
  ];
}
