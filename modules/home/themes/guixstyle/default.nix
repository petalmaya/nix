{ config, lib, ... }: {
  options.nixtop.themes.guixstyle.enable = lib.mkEnableOption "Guixstyle Theme";

  imports = [
    ./sway
    ./waybar
    ./swaync
  ];
}
