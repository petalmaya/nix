{ pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = pkgs.swayfx;

    config = rec {
      modifier = "Mod4";
      terminal = "foot";
      bars = [ { command = "waybar"; } ];
      
      fonts = {
        names = [ "DejaVu Sans Mono" ];
        size = 11.0;
      };

      # Output displays (keeping generic for now or using user's if preferred)
      # Guix config used: output * { bg ~/media/pictures/wallpapers/background stretch }
      output = {
        "*" = {
          bg = "~/media/pictures/wallpapers/background stretch";
        };
      };

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_variant = "dvorak";
          xkb_options = "ctrl:swapcaps,altwin:swap_alt_win";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
        "*" = {
          repeat_delay = "250";
          repeat_rate = "40";
        };
      };

      # Default layout
      workspaceLayout = "tabbed";

      # Workspace assignments
      assigns = {
        "2" = [ { app_id = "org.keepassxc.KeePassXC"; } { app_id = "LibreWolf"; } ];
        "3" = [ { app_id = "mpv"; } ];
        "8" = [ { app_id = "org.pwmt.zathura"; } ];
        "9" = [ { app_id = "mpv-album"; } ];
        "10" = [ { app_id = "signal"; } { app_id = "org.gajim.Gajim"; } ];
      };

      # Autostart applications
      startup = [
        { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "swayidle -w timeout 900 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock'"; }
        { command = "swaync"; always = true; }
        { command = "keepassxc --minimized"; }
      ];

      # Theming
      colors = {
        focused = { border = "#ebdbb2"; background = "#ffa21f"; text = "#282828"; indicator = "#ebdbb2"; childBorder = "#ebdbb2"; };
        # Use defaults or reasonable fallbacks for others
      };

      # Keybindings (Normal Keybinds + Guix Utilities)
      keybindings = let
        alt = "Mod1";
      in lib.mkOptionDefault {
        # --- Normal Keybinds ---
        "${modifier}+Return" = "exec foot";
        "${modifier}+d" = "exec noctalia-shell ipc call launcher toggle";
        "${modifier}+k" = "exec $HOME/.local/bin/wl-kaomoji";
        "${modifier}+Shift+d" = "exec rofi --show drun";
        "${modifier}+Shift+c" = "reload";

        "Print" = "exec grim -g \"$(slurp)\" ~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png";
        "${modifier}+l" = "exec swaylock --image ~/.lock.png --scaling fill --ring-color f6a6aa --key-hl-color 1c262c --text-color f2d7d8";
        "${modifier}+w" = "exec vivaldi";
        "${modifier}+e" = "exec foot -e yazi";
        "${modifier}+m" = "exec foot -e rmpc";
        "${modifier}+n" = "exec mpv --player-operation-mode=pseudo-gui";

        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

        "${modifier}+c" = "kill";
        "${alt}+F4" = "kill";

        "${modifier}+h" = "split h";
        "${modifier}+v" = "split v";
        "${modifier}+s" = "layout toggle split";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+space" = "floating toggle";
        "${modifier}+Shift+space" = "focus mode_toggle";

        "${modifier}+Control+Right" = "workspace next";
        "${modifier}+Control+Left" = "workspace prev";
        
        # Workspaces 1-10
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";

        "${modifier}+BackSpace" = "exec swaymsg reload";
        "${modifier}+q" = "exec swaynag -t warning -m 'Really exit?' -b 'Yes' 'swaymsg exit'";
        "${modifier}+r" = "mode resize";

        # --- Guix Unique Keybinds ---
        "${modifier}+Shift+n" = "exec guix shell firefox -- firefox https://netflix.com";
        "${modifier}+v" = "exec wl-paste | xargs vid";
        "${modifier}+Shift+v" = "exec wl-paste | xargs vd";
        "${modifier}+Shift+t" = "exec toggle-theme.scm";
        "${modifier}+a" = "exec control-music.scm track";
        "${modifier}+Tab" = "focus right";
        "${modifier}+Shift+Tab" = "focus left";
      };

      modes = {
        resize = {
          Left = "resize shrink width 5 px or 5 ppt";
          Down = "resize grow height 5 px or 5 ppt";
          Up = "resize shrink height 5 px or 5 ppt";
          Right = "resize grow width 5 px or 5 ppt";
          Return = "mode default";
          Escape = "mode default";
        };
      };
    };

    extraConfig = ''
      blur enable
      layer_effects "waybar" blur enable;
      
      titlebar_border_thickness 0
      titlebar_padding 0
    '';
  };
}
