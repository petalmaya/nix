{ config, lib, pkgs, inputs, ... }: {
  options.nixtop.themes.roseniri.enable = lib.mkEnableOption "Roseniri Theme (Niri + Noctalia Shell)";

  imports = [
    ./niri
  ];

  config = lib.mkIf config.nixtop.themes.roseniri.enable {
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

    programs.noctalia = {
      enable = true;
      # Note: Legacy v4 plugins are incompatible with v5.
    };
  };
}
