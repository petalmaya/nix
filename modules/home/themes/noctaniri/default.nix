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
      settings = {
        theme.templates.builtin_ids = [ "niri" ];
      };
    };
  };
}
