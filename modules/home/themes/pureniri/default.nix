{ config, lib, pkgs, inputs, ... }: {
  options.nixtop.themes.pureniri.enable = lib.mkEnableOption "Pureniri Theme (Niri + Noctalia Shell from NNN)";

  imports = [
    ./niri
  ];

  config = lib.mkIf config.nixtop.themes.pureniri.enable {
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    programs.noctalia = {
      enable = true;
      # Note: Legacy v4 plugins are incompatible with v5.
    };

    # Noctalia Shell configuration files
    xdg.configFile."noctalia/settings.json".text = builtins.readFile ./settings.json;

    # Fuzzel configuration and theme files
    xdg.configFile."fuzzel/fuzzel.ini".text = builtins.readFile ./fuzzel.ini;
    xdg.configFile."fuzzel/themes/noctalia".text = builtins.readFile ./fuzzel-theme-noctalia;
    xdg.configFile."fuzzel/config.json".text = builtins.readFile ./fuzzel-config.json;
  };
}
