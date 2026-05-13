{ config, lib, ... }: {
  options.nixtop.themes.redpine.enable = lib.mkEnableOption "Redpine Theme";

  imports = [
    ./sway
    ./waybar
    ./wofi
  ];
}
