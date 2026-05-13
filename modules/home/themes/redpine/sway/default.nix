{ pkgs, lib, config, ... }:

lib.mkIf config.nixtop.themes.redpine.enable {
  services.swayosd.enable = true;
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
        names = [ "Courier Prime" ];
        size = 11.0;
      };
      # Output displays
      output = {
        "*" = { bg = "/home/alice/nix/assets/wallpaper/forest_bg.jpg fill"; };
        "HDMI-A-1" = { pos = "0 0"; };
        "eDP-1" = { pos = "1680 0"; };
      };

      # Touchscreen Input
      input = {
        "3823:49229:eGalax_Inc._eGalaxTouch_EXC3000-0367-46.00.00" = {
          map_to_output = "eDP-1";
        };
      };
      # Autostart applications
      startup = [
        { command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway"; }
        { command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "keepassxc --minimized"; }
        { command = "mako"; always = false; }
      ];

      # Border styling and Window Rules
      window = {
        border = 3;
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
        border = 3;
        modifier = modifier;
      };

      gaps = {
        inner = 0;
        outer = 0;
        smartGaps = false;
      };

      # Theming
      colors = {
        focused = { border = "#661b2a"; background = "#661b2a"; text = "#e0def4"; indicator = "#661b2a"; childBorder = "#661b2a"; };
        focusedInactive = { border = "#4a1c25"; background = "#4a1c25"; text = "#908caa"; indicator = "#4a1c25"; childBorder = "#4a1c25"; };
        unfocused = { border = "#2a1015"; background = "#2a1015"; text = "#6e6a86"; indicator = "#2a1015"; childBorder = "#2a1015"; };
        urgent = { border = "#eb6f92"; background = "#eb6f92"; text = "#e0def4"; indicator = "#eb6f92"; childBorder = "#eb6f92"; };
        placeholder = { border = "#2a1015"; background = "#2a1015"; text = "#e0def4"; indicator = "#2a1015"; childBorder = "#2a1015"; };
        background = "#191724";
      };

      # Keybindings
      keybindings = let
        alt = "Mod1";
      in lib.mkOptionDefault {
        "${modifier}+Return" = "exec foot";
        "${modifier}+d" = "exec wofi --show drun --allow-images";
        "${modifier}+k" = "exec $HOME/.local/bin/wl-kaomoji";
        "${modifier}+Shift+c" = "reload";

        "Print" = "exec grim -g \"$(slurp)\" ~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png";
        "${modifier}+l" = "exec swaylock --image ~/.lock.png --scaling fill --ring-color f6a6aa --key-hl-color 1c262c --text-color f2d7d8";
        "${modifier}+w" = "exec floorp";
        "${modifier}+e" = "exec foot -e yazi";
        "${modifier}+m" = "exec foot -e rmpc";
        "${modifier}+n" = "exec mpv --player-operation-mode=pseudo-gui";

        "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
        "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
        "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
        "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
        "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";

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
        "${modifier}+1" = "workspace 1:1";
        "${modifier}+2" = "workspace 2:2";
        "${modifier}+3" = "workspace 3:3";
        "${modifier}+4" = "workspace 4:4";
        "${modifier}+5" = "workspace 5:5";
        "${modifier}+6" = "workspace 6:6";

        "${modifier}+Shift+1" = "move container to workspace 1:1";
        "${modifier}+Shift+2" = "move container to workspace 2:2";
        "${modifier}+Shift+3" = "move container to workspace 3:3";
        "${modifier}+Shift+4" = "move container to workspace 4:4";
        "${modifier}+Shift+5" = "move container to workspace 5:5";
        "${modifier}+Shift+6" = "move container to workspace 6:6";

        "${modifier}+BackSpace" = "exec swaymsg reload";
        "${modifier}+q" = "exec swaynag -t warning -m 'Really exit?' -b 'Yes' 'swaymsg exit'";
        "${modifier}+r" = "mode resize";
      };

      # Resize Mode
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
     extraConfig = builtins.readFile ./extraConfig.conf;
  };
}
