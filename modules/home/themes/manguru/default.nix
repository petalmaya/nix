# mango + nagarebar (quickshell, shared with the nagare theme), themed
# by matugen
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.manguru;
  nagarebar = import ../nagare/package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
in {
  options.nixtop.themes.manguru.enable = lib.mkEnableOption "Manguru Theme (MangoWC + nagare-shell / Quickshell)";
  options.nixtop.themes.manguru.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Where this repo is cloned, used for the ~/.config/quickshell symlink.
    '';
  };

  imports = [
    ./mango
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

    # same shell as nagare - nagarebar's mango backend (Data/MangoWC.qml)
    # is what makes this theme possible in the first place, no need to fork it
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
