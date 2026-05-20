{ config, lib, pkgs, ... }: {
  options.nixtop.themes.niriforest.enable = lib.mkEnableOption "Niriforest Theme";

  config = lib.mkIf config.nixtop.themes.niriforest.enable {
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
    ./niri
    ./wofi
  ];
}
