{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  # osConfig is only set under NixOS home-manager; fall back to local config standalone.
  desktopEnabled =
    if osConfig != null then
      (osConfig.nixtop.desktop.enable or false)
    else
      (lib.attrByPath [ "nixtop" "desktop" "enable" ] false config);
  swayEnabled = config.nixtop.sway.enable or false;
  shouldEnable = desktopEnabled || swayEnabled;
in
{
  options.nixtop.apps.gtk.enable = lib.mkOption {
    type = lib.types.bool;
    default = shouldEnable;
    defaultText = lib.literalExpression "nixtop.desktop.enable || nixtop.sway.enable";
    description = "Enable GTK theming with Papirus-Dark icons (fixes Nautilus fallback icons).";
  };

  config = lib.mkIf config.nixtop.apps.gtk.enable {
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
      # Null so matugen's gtk4 pinaceae.css owns GTK4 theming.
      gtk4.theme = null;
    };

    home.packages = with pkgs; [
      papirus-icon-theme
      adw-gtk3
      capitaine-cursors
      hicolor-icon-theme
      adwaita-icon-theme
    ];

    home.pointerCursor = {
      name = lib.mkDefault "capitaine-cursors";
      package = lib.mkDefault pkgs.capitaine-cursors;
      size = lib.mkDefault 24;
      gtk.enable = lib.mkDefault true;
    };

    dconf.enable = lib.mkDefault true;
    dconf.settings."org/gnome/desktop/interface" = {
      gtk-theme = lib.mkDefault "adw-gtk3-dark";
      icon-theme = lib.mkDefault "Papirus-Dark";
      color-scheme = lib.mkDefault "prefer-dark";
    };

    xdg.configFile."gtk-3.0/settings.ini".force = lib.mkForce false;
  };
}
