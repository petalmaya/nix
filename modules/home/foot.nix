{ pkgs, lib, ... }:
{
  # Foot :p
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "Courier Prime:size=11";
        shell = "${pkgs.zsh}/bin/zsh";
      };
      colors = {
        alpha = "0.8";
        background = "2b3339";
        foreground = "d3c6aa";

        regular0 = "4b565c"; # black
        regular1 = "e67e80"; # red
        regular2 = "a7c080"; # green
        regular3 = "dbbc7f"; # yellow
        regular4 = "7fbbb3"; # blue
        regular5 = "d699b6"; # magenta
        regular6 = "83c092"; # cyan
        regular7 = "d3c6aa"; # white

        bright0 = "5c6a72"; # bright black
        bright1 = "f85552"; # bright red
        bright2 = "8da101"; # bright green
        bright3 = "dfa000"; # bright yellow
        bright4 = "3a94c5"; # bright blue
        bright5 = "df69ba"; # bright magenta
        bright6 = "35a77c"; # bright cyan
        bright7 = "dfddbd"; # bright white

        flash = "dbbc7f"; # yellow
        cursor = "2b3339 d3c6aa";
      };
    };
  };
}