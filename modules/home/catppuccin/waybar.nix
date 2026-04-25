{ pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        spacing = 4;
        modules-left = [ "sway/workspaces" ];
        modules-center = [ ];
        modules-right = [ "clock" ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };

        "clock" = {
          format = "{:%H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };
      };
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "Courier Prime", "Symbols Nerd Font", monospace;
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background-color: #1e1e2e;
        color: #cdd6f4;
        border-bottom: 1px solid #313244;
      }

      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: #cdd6f4;
      }

      #workspaces button.focused {
        background-color: #313244;
        color: #89b4fa;
      }

      #workspaces button:hover {
        background-color: #45475a;
      }

      #clock {
        padding: 0 10px;
        background-color: #313244;
        color: #cdd6f4;
      }
    '';
  };
}
