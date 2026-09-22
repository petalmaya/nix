{ pkgs, ... }:
{
  imports = [ ../base.nix ];

  home.username = "lewis";
  home.homeDirectory = "/home/lewis";

  nixtop = {
    apps.chromium.enable = true;
  };

  home.packages = [ pkgs.git ];
}
