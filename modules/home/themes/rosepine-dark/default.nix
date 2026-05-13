{ config, lib, ... }: {
  options.nixtop.themes.rosepine-dark.enable = lib.mkEnableOption "Rosepine Dark Theme";

  imports = [
    ./sway
    ./waybar
    ./wofi
  ];
}
