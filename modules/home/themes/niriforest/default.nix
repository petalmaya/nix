{ config, lib, ... }: {
  options.nixtop.themes.niriforest.enable = lib.mkEnableOption "Niriforest Theme";

  imports = [
    ./niri
    ./wofi
  ];
}
