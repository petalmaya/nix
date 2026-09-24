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
    apps.emacs.enable = true;
  };
}
