{ config, lib, pkgs, ... }: {
  options.nixtop.themes.niripine.enable = lib.mkEnableOption "Niripine Theme";

  config = lib.mkIf config.nixtop.themes.niripine.enable {
    gtk = {
      enable = true;
      theme = {
        name = "rose-pine";
        package = pkgs.rose-pine-gtk-theme;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    home.pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
    };
  };

  imports = [
    ./niri
    ./waybar
    ./wofi
  ];
}
