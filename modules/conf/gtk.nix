{ config, lib, pkgs, osConfig ? null, ... }:
let
  # Enable GTK/Papirus theming whenever the desktop or sway is active.
  # osConfig is available when this HM module is evaluated via NixOS's home-manager;
  # fall back to local config when evaluated standalone.
  desktopEnabled =
    if osConfig != null then (osConfig.nixtop.desktop.enable or false)
    else (lib.attrByPath [ "nixtop" "desktop" "enable" ] false config);
  swayEnabled = (config.nixtop.sway.enable or false);
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
      # HM would otherwise set gtk4 theme to Adwaita; we keep it null so
      # matugen's gtk4 pinaceae.css (modules/matugen) owns GTK4 theming.
      gtk4.theme = null;
    };

    # Ensure the icon theme and cursor are available even without matugen
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

    # gsettings/dconf is required for GTK to pick up the icon theme live
    dconf.enable = lib.mkDefault true;
    dconf.settings."org/gnome/desktop/interface" = {
      gtk-theme = lib.mkDefault "adw-gtk3-dark";
      icon-theme = lib.mkDefault "Papirus-Dark";
      color-scheme = lib.mkDefault "prefer-dark";
    };

    # Help Nautilus/GTK apps find the theme without logging out
    xdg.configFile."gtk-3.0/settings.ini".force = lib.mkForce false;
  };
}
