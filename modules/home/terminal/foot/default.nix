{ pkgs, lib, ... }:
{
  # Foot :p
  programs.foot = {
    enable = true;
  };

  xdg.configFile."foot/foot.ini".source = ./foot.ini;
}
