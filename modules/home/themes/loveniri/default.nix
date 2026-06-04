{ config, lib, pkgs, inputs, ... }: {
  options.nixtop.themes.loveniri.enable = lib.mkEnableOption "Loveniri Theme (Niri + Noctalia Shell with enhanced keybinds)";

  imports = [
    ./niri
  ];

  config = lib.mkIf config.nixtop.themes.loveniri.enable {
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

    programs.noctalia-shell = {
      enable = true;
      plugins = [
        "screentoolkit"
        "clipper"
        "assistant-panel"
        "mpd-mpris"
      ];
    };
  };
}
