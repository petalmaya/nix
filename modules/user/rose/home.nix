{ pkgs, ... }: {
  imports = [
    ./flatnix.nix
    ../base.nix
  ];

  home = {
    username = "rose";
    homeDirectory = "/home/rose";

    packages = with pkgs; [
      vesktop
    ];
  };

  nixtop = {
    apps.emacs.enable = true;
  };
}
