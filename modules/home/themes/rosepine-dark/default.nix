{ config, lib, pkgs, ... }: {
  options.nixtop.themes.rosepine-dark.enable = lib.mkEnableOption "Rosepine Dark Theme";

  config = lib.mkIf config.nixtop.themes.rosepine-dark.enable {
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
    ./sway
    ./waybar
    ./wofi
  ];
}
