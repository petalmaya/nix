{ pkgs, lib, config, ... }:

lib.mkIf config.nixtop.themes.guixstyle.enable {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = pkgs.swayfx;

    # Native Home Manager Sway Configuration
    config = rec {
      modifier = "Mod4";
      terminal = "foot";
      bars = [];
      fonts = {
        names = [ "DejaVu Sans Mono" ];
        size = 11.0;
      };

      # Output displays — replace with your actual wallpaper path
      output = {
        "*" = { bg = "/home/alice/nix/assets/wallpaper/guixstyle_bg.png fill"; };
        "HDMI-A-1" = { pos = "0 0"; };
        "eDP-1" = { pos = "1680 0"; };
      };

      # Keyboard & touchpad input
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
        "2"  = [ { app_id = "org.keepassxc.KeePassXC"; } { app_id = "LibreWolf"; } ];
        "3"  = [ { app_id = "mpv"; } ];
        "8"  = [ { app_id = "org.pwmt.zathura"; } ];
        "9"  = [ { app_id = "mpv-album"; } ];
        "10" = [ { app_id = "signal"; } { app_id = "org.gajim.Gajim"; } ];
      };

      # Autostart applications
      startup = [
        { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "keepassxc --minimized"; }
        { command = "swayidle -w timeout 900 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock'"; }
        { command = "waybar"; always = true; }
        { command = "swaync"; always = true; }
      ];

      # Border styling and Window Rules
      window = {
        border = 2;
        titlebar = false;
        commands = [
          { command = "floating enable, focus"; criteria = { app_id = "(?i)eog|sxiv|feh|mpv|vlc|file-roller|xarchiver"; }; }
          { command = "floating enable, focus"; criteria = { class = "(?i)eog|sxiv|feh|mpv|vlc|file-roller|xarchiver"; }; }
          { command = "floating enable"; criteria = { window_role = "dialog"; }; }
          { command = "floating enable"; criteria = { window_role = "pop-up"; }; }
          { command = "floating enable"; criteria = { window_type = "dialog"; }; }
          { command = "floating enable"; criteria = { window_type = "menu"; }; }
          { command = "floating enable"; criteria = { app_id = "thunar"; title = "File Operation Progress"; }; }
          { command = "floating enable, sticky enable, focus"; criteria = { app_id = "thunar"; title = "Confirm to replace files"; }; }
        ];
      };

      floating = {
        border = 2;
        modifier = modifier;
      };

      gaps = {
        inner = 0;
        outer = 0;
        smartGaps = false;
      };

      # Guixstyle warm dark brown color scheme
      # bg: #352718  accent: #ffa21f  green: #6fd560
      colors = {
        focused         = { border = "#ffa21f"; background = "#ffa21f"; text = "#282828"; indicator = "#6fd560"; childBorder = "#ffa21f"; };
        focusedInactive = { border = "#352718"; background = "#352718"; text = "#e8e4b1"; indicator = "#352718"; childBorder = "#352718"; };
        unfocused       = { border = "#282828"; background = "#282828"; text = "#9da9a0"; indicator = "#282828"; childBorder = "#282828"; };
        urgent          = { border = "#b02930"; background = "#b02930"; text = "#e8e4b1"; indicator = "#b02930"; childBorder = "#b02930"; };
        placeholder     = { border = "#352718"; background = "#352718"; text = "#e8e4b1"; indicator = "#352718"; childBorder = "#352718"; };
        background      = "#352718";
      };

      # Keybindings
      keybindings = let
        alt = "Mod1";
      in lib.mkOptionDefault {
        "${modifier}+Return"      = "exec foot";
        "${modifier}+Shift+f"    = "exec fuzzel";
        "${modifier}+k"          = "exec $HOME/.local/bin/wl-kaomoji";
        "${modifier}+Shift+c"    = "reload";

        "Print" = "exec grim -g \"$(slurp)\" ~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png";
        "${modifier}+l" = "exec swaylock";
        "${modifier}+w" = "exec librewolf";
        "${modifier}+e" = "exec foot -e yazi";
        "${modifier}+b" = "exec librewolf";
        "${modifier}+m" = "exec foot -e rmpc";
        "${modifier}+n" = "exec mpv --player-operation-mode=pseudo-gui";

        "XF86AudioRaiseVolume"    = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume"    = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute"           = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86MonBrightnessUp"     = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown"   = "exec brightnessctl set 5%-";

        "${modifier}+c"           = "kill";
        "${alt}+F4"               = "kill";

        "${modifier}+h"           = "split h";
        "${modifier}+v"           = "split v";
        "${modifier}+s"           = "layout toggle split";
        "${modifier}+t"           = "layout tabbed";
        "${modifier}+f"           = "fullscreen toggle";
        "${modifier}+space"       = "floating toggle";
        "${modifier}+Shift+space" = "focus mode_toggle";

        "${modifier}+Tab"         = "focus right";
        "${modifier}+Shift+Tab"   = "focus left";
        "${modifier}+c"           = "workspace back_and_forth";

        "${modifier}+Control+Right" = "workspace next";
        "${modifier}+Control+Left"  = "workspace prev";

        "${modifier}+1"  = "workspace number 1";
        "${modifier}+2"  = "workspace number 2";
        "${modifier}+3"  = "workspace number 3";
        "${modifier}+4"  = "workspace number 4";
        "${modifier}+5"  = "workspace number 5";
        "${modifier}+6"  = "workspace number 6";
        "${modifier}+7"  = "workspace number 7";
        "${modifier}+8"  = "workspace number 8";
        "${modifier}+9"  = "workspace number 9";
        "${modifier}+0"  = "workspace number 10";

        "${modifier}+Shift+1"  = "move container to workspace number 1";
        "${modifier}+Shift+2"  = "move container to workspace number 2";
        "${modifier}+Shift+3"  = "move container to workspace number 3";
        "${modifier}+Shift+4"  = "move container to workspace number 4";
        "${modifier}+Shift+5"  = "move container to workspace number 5";
        "${modifier}+Shift+6"  = "move container to workspace number 6";
        "${modifier}+Shift+7"  = "move container to workspace number 7";
        "${modifier}+Shift+8"  = "move container to workspace number 8";
        "${modifier}+Shift+9"  = "move container to workspace number 9";
        "${modifier}+Shift+0"  = "move container to workspace number 10";

        "${modifier}+minus"       = "scratchpad show";
        "${modifier}+Shift+minus" = "move scratchpad";

        "${modifier}+BackSpace"   = "exec swaymsg reload";
        "${modifier}+q"           = "exec swaynag -t warning -m 'Really exit?' -b 'Yes' 'swaymsg exit'";
        "${modifier}+r"           = "mode resize";

        # Guix-specific
        "${modifier}+Shift+n" = "exec guix shell firefox -- firefox https://netflix.com";
        "${modifier}+a"       = "exec control-music.scm track";
        "${modifier}+Shift+t" = "exec toggle-theme.scm";
      };

      # Resize Mode
      modes = {
        resize = {
          Left   = "resize shrink width 5 px or 5 ppt";
          Down   = "resize grow height 5 px or 5 ppt";
          Up     = "resize shrink height 5 px or 5 ppt";
          Right  = "resize grow width 5 px or 5 ppt";
          Return = "mode default";
          Escape = "mode default";
        };
      };
    };
    extraConfig = builtins.readFile ./extraConfig.conf;
  };
}
