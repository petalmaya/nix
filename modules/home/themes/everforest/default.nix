{ config, lib, pkgs, ... }: {
  options.nixtop.themes.everforest.enable = lib.mkEnableOption "Everforest Theme";

  config = lib.mkIf config.nixtop.themes.everforest.enable {
    gtk = {
      enable = true;
      theme = {
        name = "Everforest-Dark-B";
        package = pkgs.everforest-gtk-theme;
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
    ./sway
    ./waybar
    ./wofi
  ];
}
