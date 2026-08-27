# mango + kurukurubar (quickshell, shared with the kurukuru theme), themed
# by matugen
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.manguru;
  kurukurubar = import ../kurukuru/package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
in {
  options.nixtop.themes.manguru.enable = lib.mkEnableOption "Manguru Theme (MangoWC + Kuru Kuru Bar / Quickshell)";
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

    # same shell as kurukuru - kurukurubar's mango backend (Data/MangoWC.qml)
    # is what makes this theme possible in the first place, no need to fork it
    home.file.".config/quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/themes/kurukuru/quickshell";

    home.packages = [
      kurukurubar
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
    ];

    # kurukurubar has its own notification server, mako would race it for
    # the dbus name
    services.mako.enable = lib.mkForce false;
  };
}
