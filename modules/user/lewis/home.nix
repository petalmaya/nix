{ pkgs, ... }:
{
  imports = [ ../base.nix ];

  home = {
    username = "lewis";
    homeDirectory = "/home/lewis";
    packages = [ pkgs.git ];
  };

  nixtop = {
    apps.chromium.enable = true;
  };
}
