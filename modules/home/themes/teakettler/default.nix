# mango + teakettler's own quickshell fork (see ./package.nix), with
# teakettler's split mango configs + static pinaceae/foot theme.
# starship + fastfetch come from matugen on ALL themes (see
# modules/home/services/matugen), not per-theme.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.teakettler;
  teakettlerShell = import ./package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
in {
  options.nixtop.themes.teakettler.enable = lib.mkEnableOption "Teakettler Theme (MangoWC + teakettler-shell / Quickshell)";
  options.nixtop.themes.teakettler.repoPath = lib.mkOption {
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

    home.file.".config/quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/themes/teakettler/quickshell";

    home.packages = [
      teakettlerShell
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
    ];

    services.mako.enable = lib.mkForce false;
  };
}
