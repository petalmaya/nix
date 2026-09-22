{ config, pkgs, ... }:
{
  imports = [
    ./flatnix.nix
    ../base.nix
  ];

  home.username = "rose";
  home.homeDirectory = "/home/rose";

  nixtop = {
    apps.chromium.enable = true;
    apps.emacs.enable = true;
  };

  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";

  home.packages = [ pkgs.git ];

  xdg.userDirs = {
    createDirectories = true;
    templates = "${config.home.homeDirectory}/Templates";
  };
}
