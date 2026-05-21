{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.niriforest.enable {
  programs.niri = {
    enable = true;

    settings = {

      # Output displays — mirrors sway output positions
      outputs = {
        "HDMI-A-1" = {
          position = { x = 0; y = 0; };
        };
        "eDP-1" = {
          position = { x = 1680; y = 0; };
        };
      };

      # Input
      input = {
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
        touch.map-to-output = "eDP-1";
      };

      # Autostart
      spawn-at-startup = [
        { command = [ "swaybg" "-i" "${inputs.self}/assets/wallpaper/forest_bg.jpg" "-m" "fill" ]; }
        { command = [ "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri" ]; }
        { command = [ "systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" ]; }
        { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        { command = [ "keepassxc" "--minimized" ]; }
        { command = [ "mako" ]; }
        { command = [ "waybar" ]; }
      ];

      # Layout
      layout = {
        gaps = 12;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 0.333; }
          { proportion = 0.5; }
          { proportion = 0.667; }
          { proportion = 1.0; }
        ];
        default-column-width = { proportion = 0.5; };

        # Border colours mirror sway everforest colours
        focus-ring = {
          enable = true;
          width = 3;
          active.color = "#a7c080";   # everforest green
          inactive.color = "#3a454a"; # everforest dim
        };
        border.enable = false;
      };

      # Prefer server-side decorations
      prefer-no-csd = true;

      # Window rules
      window-rules = [
        {
          matches = [{ app-id = "^(eog|sxiv|feh|mpv|vlc|file-roller|xarchiver)$"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = "thunar"; title = "File Operation Progress"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = "thunar"; title = "Confirm to replace files"; }];
          open-floating = true;
        }
      ];

      animations.enable = true;

      cursor = {
        theme = "Adwaita";
        size = 24;
      };

      environment = {
        XDG_CURRENT_DESKTOP = "niri";
      };

      # Keybindings
      binds = {
        # Terminal / launcher
        "Mod+Return"      = { action.spawn = [ "foot" ]; };
        "Mod+D"           = { action.spawn = [ "wofi" "--show" "drun" "--allow-images" ]; };
        "Mod+Shift+K"     = { action.spawn = [ "sh" "-c" "$HOME/.local/bin/wl-kaomoji" ]; };

        # Screenshot
        "Print"           = { action.spawn = [ "sh" "-c" "grim -g \"$(slurp)\" ~/Pictures/$(date +%Y-%m-%d_%H-%m-%s).png" ]; };

        # Lock
        "Mod+Shift+L"     = { action.spawn = [
          "swaylock" "--image" "/home/alice/.lock.png" "--scaling" "fill"
          "--ring-color" "f6a6aa" "--key-hl-color" "1c262c" "--text-color" "f2d7d8"
        ]; };

        # Apps
        "Mod+W"           = { action.spawn = [ "floorp" ]; };
        "Mod+E"           = { action.spawn = [ "foot" "-e" "yazi" ]; };
        "Mod+M"           = { action.spawn = [ "foot" "-e" "rmpc" ]; };
        "Mod+N"           = { action.spawn = [ "mpv" "--player-operation-mode=pseudo-gui" ]; };

        # Audio / brightness
        "XF86AudioRaiseVolume"    = { action.spawn = [ "swayosd-client" "--output-volume" "raise" ]; };
        "XF86AudioLowerVolume"    = { action.spawn = [ "swayosd-client" "--output-volume" "lower" ]; };
        "XF86AudioMute"           = { action.spawn = [ "swayosd-client" "--output-volume" "mute-toggle" ]; };
        "XF86MonBrightnessUp"     = { action.spawn = [ "swayosd-client" "--brightness" "raise" ]; };
        "XF86MonBrightnessDown"   = { action.spawn = [ "swayosd-client" "--brightness" "lower" ]; };

        # Window management
        "Mod+C"           = { action.close-window = {}; };
        "Alt+F4"          = { action.close-window = {}; };

        "Mod+F"           = { action.maximize-column = {}; };
        "Mod+Shift+F"     = { action.fullscreen-window = {}; };
        "Mod+Space"       = { action.toggle-window-floating = {}; };
        "Mod+Shift+Space" = { action.switch-focus-between-floating-and-tiling = {}; };

        # Focus movement (arrow keys + hjkl-ish)
        "Mod+Left"        = { action.focus-column-left = {}; };
        "Mod+Right"       = { action.focus-column-right = {}; };
        "Mod+Up"          = { action.focus-window-up = {}; };
        "Mod+Down"        = { action.focus-window-down = {}; };
        "Mod+H"           = { action.focus-column-left = {}; };
        "Mod+J"           = { action.focus-window-down = {}; };
        "Mod+K"           = { action.focus-window-up = {}; };
        "Mod+L"           = { action.focus-column-right = {}; };

        # Move columns
        "Mod+Shift+Left"  = { action.move-column-left = {}; };
        "Mod+Shift+Right" = { action.move-column-right = {}; };
        "Mod+Shift+H"     = { action.move-column-left = {}; };
        "Mod+Shift+J"     = { action.move-column-right = {}; };

        # Workspaces
        "Mod+Control+Right" = { action.focus-workspace-down = {}; };
        "Mod+Control+Left"  = { action.focus-workspace-up = {}; };
        "Mod+1"             = { action.focus-workspace = 1; };
        "Mod+2"             = { action.focus-workspace = 2; };
        "Mod+3"             = { action.focus-workspace = 3; };
        "Mod+4"             = { action.focus-workspace = 4; };
        "Mod+5"             = { action.focus-workspace = 5; };
        "Mod+6"             = { action.focus-workspace = 6; };
        "Mod+Shift+1"       = { action.move-column-to-workspace = 1; };
        "Mod+Shift+2"       = { action.move-column-to-workspace = 2; };
        "Mod+Shift+3"       = { action.move-column-to-workspace = 3; };
        "Mod+Shift+4"       = { action.move-column-to-workspace = 4; };
        "Mod+Shift+5"       = { action.move-column-to-workspace = 5; };
        "Mod+Shift+6"       = { action.move-column-to-workspace = 6; };

        # Column sizing
        "Mod+Minus" = { action.set-column-width = "-10%"; };
        "Mod+Equal" = { action.set-column-width = "+10%"; };
        "Mod+R"     = { action.switch-preset-column-width = {}; };

        # Quit
        "Mod+Q"           = { action.quit = {}; };
        "Mod+Shift+C"     = { action.do-screen-transition = {}; };

        # Show keybind overlay
        "Mod+Shift+Slash" = { action.show-hotkey-overlay = {}; };
      };
    };
  };

  # swayosd works under niri
  services.swayosd.enable = true;

  home.packages = with pkgs; [
    swaybg
    swaylock
    grim
    slurp
    mako
  ];
}
