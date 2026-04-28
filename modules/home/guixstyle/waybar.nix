{ ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 4;
        fixed-center = false;
        modules-left = [ "sway/workspaces" "sway/window" ];
        modules-right = [ "wireplumber" "network" "cpu" "memory" "backlight" "battery" "clock" "tray" ];

        "sway/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          active-only = false;
          all-outputs = true;
          persistent-workspaces = {
            "1" = [ ]; "2" = [ ]; "3" = [ ]; "4" = [ ]; "5" = [ ];
            "6" = [ ]; "7" = [ ]; "8" = [ ]; "9" = [ ]; "10" = [ ];
          };
          format-icons = {
            "1" = "I"; "2" = "II"; "3" = "III"; "4" = "IV"; "5" = "V";
            "6" = "VI"; "7" = "VII"; "8" = "VIII"; "9" = "IX"; "10" = "X";
          };
        };

        "sway/window" = {
          format = " {}";
          max-length = 35;
        };

        tray = {
          spacing = 10;
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-muted = " {volume}%";
          format-icons = {
            default = [ "" "" "" ];
          };
        };

        clock = {
          timezone = "America/New_York";
          format = " {:%r}";
          interval = 1;
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = " {:%a, %b %d}";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [ "" "" "" "" "" "" "" "" "" ];
        };

        battery = {
          states = {
            full = 100;
            good = 95;
            critical = 20;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ "" "" "" "" "" ];
        };

        network = {
          format-wifi = " {ifname}";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{essid} via {gwaddr}";
          format-disconnected = "Disconnected ⚠";
        };
      };
    };
    style = ''
      * {
          border: none;
          border-radius: 0;
          font-family: DejaVu Sans Mono, FontAwesome, monospace;
          font-size: 20px;
      }

      window#waybar {
          background-color: rgba(53,39,24,0.75);
          color: #ffffff;
      }

      tooltip {
          background: #352718;
          border: 1px solid #5d5f63;
      }

      tooltip label {
        color: white;
      }

      #workspaces button {
          color: #ffa21f;
      }

      #workspaces button.persistent {
          color: #ffffff
      }

      #workspaces button.focused {
          color: #6fd560;
      }

      #workspaces button:hover {
          background: #fff6d8;
          color: #484431;
      }

      #window {
          margin-left: 0px;
          margin-right: 0px;
      }

      #pulseaudio,#wireplumber,#network,#cpu,#memory,#backlight,#battery,#clock {
          margin-left: 5px;
          margin-right: 5px;
      }

      #wireplumber {
          border-top: 5px solid #ffa21f;
          color:  #ffffff;
      }

      #wireplumber.muted {
          color: #887c8a;
      }

      #network {
          border-top: 5px solid #6fd560;
          color: #ffffff;
      }

      #network.disconnected {
          border-top: 5px solid #b02930;
          color: #ffffff;
      }

      #cpu {
          border-top: 5px solid #57aff6;
          color: #ffffff;
      }

      #memory {
          border-top: 5px solid #90918a;
          color: #ffffff;
      }

      #backlight {
          border-top: 5px solid #6fcad0;
          color: #ffffff;
      }

      #battery.full {
          border-top: 5px solid #a0d13a;
          color: #ffffff;
      }

      #battery.good {
          border-top: 5px solid #e4b53f;
          color: #ffffff;
      }

      #battery.critical {
          border-top: 5px solid #b02930;
          color: #ffffff;
      }

      #clock {
          border-top: 5px solid #f0aac5;
          color: #ffffff;
      }

      @keyframes blink {
          to {
              background-color: #ffffff;
              color: black;
          }
      }

      #battery.warning:not(.charging) {
          background: #f53c3c;
          color: white;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
    '';
  };
}
