# rose pine gtk + sway/waybar/wofi
{ config, lib, pkgs, ... }: {
  options.nixtop.themes.redpine.enable = lib.mkEnableOption "Redpine Theme";

  imports = [
    ./sway
    ./waybar
    ./wofi
  ];

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
      gtk4.theme = null;
    };

    home.pointerCursor = {
      enable = true;
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
    };
  };
}
