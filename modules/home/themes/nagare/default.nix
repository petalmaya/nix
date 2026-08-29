# niri + nagarebar (quickshell), themed by matugen
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.nagare;
  nagarebar = import ./package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
in {
  options.nixtop.themes.nagare.enable = lib.mkEnableOption "Nagare Theme (Niri + nagare-shell / Quickshell)";
  options.nixtop.themes.nagare.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Where this repo is cloned, used for the ~/.config/quickshell symlink.
    '';
  };

  imports = [
    ./niri
  ];

  config = lib.mkIf cfg.enable {
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
      gtk4.theme = null;
    };

    home.pointerCursor = {
      enable = true;
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
    };

    # out-of-store symlink so bare `qs` works and QML edits don't need a rebuild
    home.file.".config/quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/themes/nagare/quickshell";

    home.packages = [
      nagarebar
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
    ];

    # nagarebar has its own notification server, mako would race it for
    # the dbus name
    services.mako.enable = lib.mkForce false;
  };
}
