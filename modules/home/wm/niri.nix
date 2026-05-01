{ config, pkgs, lib, unstable-pkgs, ... }:

{
  home.packages = [
    unstable-pkgs.niri
    pkgs.swaybg
    pkgs.foot
  ];

  xdg.configFile."niri/config.kdl".text = ''
    spawn-at-startup "noctalia-shell"
    spawn-at-startup "swaybg" "-m" "fill" "-i" "${pkgs.nixos-artwork.wallpapers.nineish.src}"
    
    output "HDMI-A-1" {
        position x=0 y=0
    }

    output "eDP-1" {
        position x=1680 y=0
    }

    input {
      keyboard {
        xkb {
          layout "us"
        }
      }
      touchpad {
        tap
        natural-scroll
        dwt
      }
      mouse {
        natural-scroll
      }
    }
    
    
    layout {
      gaps 16
      center-focused-column "never"
      default-column-width { proportion 0.5; }
      focus-ring {
        width 4
        active-color "#ebbcba"
        inactive-color "#26233a"
      }
    }

    window-rule {
      match app-id="(?i)eog|sxiv|feh|mpv|vlc|file-roller|xarchiver"
      open-floating true
    }

    binds {
      // General
      Super+Return { spawn "foot"; }
      Super+D { spawn "fuzzel"; }
      Super+Q { close-window; }
      Super+Shift+E { quit; }
      Super+Shift+R { spawn "niri-msg" "reload"; }

      // Focus
      Super+Left  { focus-column-left; }
      Super+Down  { focus-window-down; }
      Super+Up    { focus-window-up; }
      Super+Right { focus-column-right; }
      Super+H     { focus-column-left; }
      Super+J     { focus-window-down; }
      Super+K     { focus-window-up; }
      Super+L     { focus-column-right; }

      // Move
      Super+Shift+Left  { move-column-left; }
      Super+Shift+Down  { move-window-down; }
      Super+Shift+Up    { move-window-up; }
      Super+Shift+Right { move-column-right; }
      Super+Shift+H     { move-column-left; }
      Super+Shift+J     { move-window-down; }
      Super+Shift+K     { move-window-up; }
      Super+Shift+L     { move-column-right; }

      // Workspaces
      Super+1 { focus-workspace 1; }
      Super+2 { focus-workspace 2; }
      Super+3 { focus-workspace 3; }
      Super+4 { focus-workspace 4; }
      Super+5 { focus-workspace 5; }
      Super+6 { focus-workspace 6; }
      Super+Shift+1 { move-column-to-workspace 1; }
      Super+Shift+2 { move-column-to-workspace 2; }
      Super+Shift+3 { move-column-to-workspace 3; }
      Super+Shift+4 { move-column-to-workspace 4; }
      Super+Shift+5 { move-column-to-workspace 5; }
      Super+Shift+6 { move-column-to-workspace 6; }

      // Layout
      Super+F { maximize-column; }
      Super+Shift+F { fullscreen-window; }
      Super+Space { toggle-window-floating; }
      Super+C { center-column; }

      Super+Minus { set-column-width "-10%"; }
      Super+Equal { set-column-width "+10%"; }

      // Media
      XF86AudioRaiseVolume { spawn "pactl" "set-sink-volume" "@DEFAULT_SINK@" "+5%"; }
      XF86AudioLowerVolume { spawn "pactl" "set-sink-volume" "@DEFAULT_SINK@" "-5%"; }
      XF86AudioMute        { spawn "pactl" "set-sink-mute"   "@DEFAULT_SINK@" "toggle"; }
      XF86MonBrightnessUp   { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }

      // Screenshot
      Print { spawn "sh" "-c" "grim -g \"$(slurp)\" -"; }
    }
  '';
}
