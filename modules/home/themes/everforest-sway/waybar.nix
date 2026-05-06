{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        spacing = 4;
        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "clock" ];
        modules-right = [ "network" "cpu" "memory" "pulseaudio" "tray" ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "[{name}]";
        };
        
        "clock" = {
          format = "{:%H:%M:%S}";
          interval = 1;
        };

        "cpu" = {
          format = "CPU:{usage}%";
        };

        "memory" = {
          format = "RAM:{percentage}%";
        };

        "network" = {
          format-wifi = "WIFI:{essid} ({signalStrength}%)";
          format-ethernet = "ETH:{ipaddr}/{cidr}";
          format-disconnected = "DISCONNECTED";
        };

        "pulseaudio" = {
          format = "VOL:{volume}%";
          format-muted = "MUTED";
        };
      };
    };

    style = ''
      * {
        font-family: "Courier Prime", monospace;
        font-size: 14px;
        min-height: 0;
        border-radius: 0; /* Fully blocky */
        font-weight: bold;
      }

      window#waybar {
        background-color: #2b3339;
        color: #d3c6aa;
        border-bottom: 3px solid #a7c080;
      }

      #workspaces button {
        padding: 0 10px;
        background-color: #3a454a;
        color: #d3c6aa;
        margin: 2px 2px;
        border: 2px solid #2b3339;
      }

      #workspaces button:hover {
        background: #4f5b66;
      }

      #workspaces button.focused {
        background-color: #a7c080;
        color: #2b3339;
        border: 2px solid #a7c080;
      }

      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray,
      #mode {
        padding: 0 10px;
        margin: 2px 2px;
        color: #a7c080;
        background-color: #2b3339;
        border: 2px solid #a7c080;
      }
      
      #clock {
        color: #d3c6aa;
        border-color: #d3c6aa;
      }
    '';
  };
}
