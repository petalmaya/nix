{ config, pkgs, ... }:
{
  imports = [
    ./flatnix.nix
    ../base.nix
  ];

  home = {
    username = "rose";
    homeDirectory = "/home/rose";
    file."Pictures/Wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/assets/wallpaper";
    packages = [ pkgs.git ];
  };

  nixtop = {
    apps.chromium.enable = true;
    apps.emacs.enable = true;
  };

  xdg.userDirs = {
    createDirectories = true;
    templates = "${config.home.homeDirectory}/Templates";
  };
}
