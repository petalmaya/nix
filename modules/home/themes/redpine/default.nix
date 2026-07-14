# Redpine theme: Rose Pine GTK colours with Papirus icons and Capitaine cursors,
# paired with a Sway/Waybar/Wofi desktop stack.
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
      # Null-out GTK4 theme to silence HM's deprecation warning.
      gtk4.theme = null;
    };

    home.pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;  # propagate cursor to GTK apps as well
    };
  };

  # Desktop environment sub-modules for this theme's compositor stack.
  imports = [
    ./sway
    ./waybar
    ./wofi
  ];
}
