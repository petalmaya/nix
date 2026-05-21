{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.rosepine-dark.enable {
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

      # Output displays — placeholder solid color background
      output = {
        "*" = { bg = "${inputs.self}/assets/wallpaper/cute_bg.png fill"; };
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
        { command = "waybar"; always = true; }
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

      # Rosepine Dark color scheme
      # base: #191724  surface: #1f1d2e  overlay: #26233a
      # love: #eb6f92  gold: #f6c177  rose: #ebbcba
      # pine: #31748f  foam: #9ccfd8  iris: #c4a7e7
      # text: #e0def4  subtle: #908caa  muted: #6e6a86
      colors = {
        focused         = { border = "#eb6f92"; background = "#1f1d2e"; text = "#e0def4"; indicator = "#9ccfd8"; childBorder = "#eb6f92"; };
        focusedInactive = { border = "#26233a"; background = "#1f1d2e"; text = "#908caa"; indicator = "#26233a"; childBorder = "#26233a"; };
        unfocused       = { border = "#191724"; background = "#191724"; text = "#6e6a86"; indicator = "#191724"; childBorder = "#191724"; };
        urgent          = { border = "#f6c177"; background = "#f6c177"; text = "#191724"; indicator = "#f6c177"; childBorder = "#f6c177"; };
        placeholder     = { border = "#191724"; background = "#191724"; text = "#e0def4"; indicator = "#191724"; childBorder = "#191724"; };
        background      = "#191724";
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
        "${modifier}+l" = "exec swaylock --color 191724 --ring-color eb6f92 --key-hl-color f6c177 --text-color e0def4";
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
