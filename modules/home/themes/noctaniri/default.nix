{ config, lib, pkgs, inputs, ... }: {
  options.nixtop.themes.noctaniri.enable = lib.mkEnableOption "Noctaniri Theme (Niri + Noctalia Shell v5)";

  imports = [
    ./niri
  ];

  config = lib.mkIf config.nixtop.themes.noctaniri.enable {
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
      # Note: Legacy v4 plugins like "screentoolkit", "clipper", "assistant-panel", 
      # and "mpd-mpris" are not supported in the v5 rewrite (which has native 
      # clipboard history and media widgets instead).
    };
  };
}
