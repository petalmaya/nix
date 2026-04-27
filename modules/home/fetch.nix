{ pkgs, lib, ... }:
{
  # Fastfetch/Hyfetch
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = ''
   <<
   __
  |  |─╮
  |__|─╯
'';
        padding = {
          right = 4;
        };
      };
      display = {
        separator = "  ";
        color = "white";
        key = {
            width = 3;
        };
      };
      modules = [
        {
          type = "os";
          key = "OS ";
        }
        {
          type = "kernel";
          key = "KER ";
        }
        {
          type = "packages";
          key = "PKG ";
        }
        {
          type = "shell";
          key = "SH ";
        }
        {
          type = "wm";
          key = "WM ";
        }
      ];
    };
  };
}
