_: {
  imports = [
    ./flatnix.nix
    ../base.nix
  ];

  home = {
    username = "rose";
    homeDirectory = "/home/rose";
  };

  nixtop = {
    wallpapers.enable = true;
    apps.emacs.enable = true;
  };
}
