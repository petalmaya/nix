# Noctaniri theme: Niri compositor + Noctalia Shell v5 desktop shell.
#
# Noctalia Shell may expose its HM modules under either `homeModules` or
# `homeManagerModules` depending on the flake revision, so we check both
# and fall back to an empty list if neither exists.
{ config, lib, pkgs, inputs, ... }: {
  options.nixtop.themes.noctaniri.enable = lib.mkEnableOption "Noctaniri Theme (Niri + Noctalia Shell v5)";

  imports = [
    ./niri
  ] ++ (if inputs.noctalia-shell ? homeModules
        # Newer flake output attribute name
        then builtins.attrValues inputs.noctalia-shell.homeModules
        else if inputs.noctalia-shell ? homeManagerModules
        # Older / alternative attribute name
        then builtins.attrValues inputs.noctalia-shell.homeManagerModules
        else []);  # neither found — graceful no-op

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
      # Null-out GTK4 theme to silence HM's deprecation warning
      # (GTK4 theming is handled separately via libadwaita overrides).
      gtk4.theme = null;
    };

    home.pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;  # also apply cursor to GTK apps
    };

    programs.noctalia = {
      enable = true;
      settings = {
        # Activate the built-in niri template so Noctalia Shell knows which
        # compositor-specific config snippets to generate.
        theme.templates.builtin_ids = [ "niri" ];
      };
    };
  };
}
