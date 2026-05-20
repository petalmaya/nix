{ config, lib, pkgs, ... }: {
  options.nixtop.themes.redpine.enable = lib.mkEnableOption "Redpine Theme";

  config = lib.mkIf config.nixtop.themes.redpine.enable {
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
