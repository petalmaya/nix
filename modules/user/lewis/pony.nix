{ lib, pkgs, ... }:
{
  nixtop = {
    apps.chromium.enable = lib.mkForce false;
    terminal.foot.enable = lib.mkForce false;
    sway.enable = lib.mkForce false;
  };

  home.packages = with pkgs; [ btop ];
}
