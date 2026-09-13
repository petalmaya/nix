{ config, lib, pkgs, ... }:
{
  # Scaffold for a Mango + waybar + rofi variant (netbsd)
  # Not imported by default – available as a switchable option.
  # To use, add ./netbsd to homeModules in modules/default.nix
  # or enable via:
  #   nixtop.netbsd.enable = true;
  #   nixtop.shell = "netbsd";  # if you extend the shell enum
  #
  # This is a scaffold only; nothing is built until you enable it.
  # Fill in waybar/rofi configs and Mango variant files as needed.

  options.nixtop.netbsd.enable = lib.mkEnableOption "NetBSD-style Mango setup (waybar + rofi)";

  config = lib.mkIf config.nixtop.netbsd.enable {
    # Waybar – HM's programs.waybar is the canonical way.
    # The style/config here are placeholders; matugen can own them later if desired.
    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          modules-left = [ "mango/workspaces" "mango/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "battery" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
        };
      };
      style = builtins.readFile ./waybar/style.css;
    };

    # Rofi – via programs.rofi (wayland-friendly). Config is a placeholder.
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = ./rofi/config.rasi;
      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
        terminal = "foot";
      };
    };

    # Mango variant for netbsd – drop these into ~/.config/mango when this variant is active.
    # Currently just placeholders that mirror the shared base; copy real values from
    # modules/mango/variants/{noctalia,quickshell} when you flesh this out.
    xdg.configFile."mango/netbsd-appearance.conf".text = builtins.readFile ./mango/appearance.conf;
    xdg.configFile."mango/netbsd-keybinds.conf".text = builtins.readFile ./mango/keybinds.conf;
    xdg.configFile."mango/netbsd-autostart.conf".text = builtins.readFile ./mango/autostart.conf;

    home.packages = with pkgs; [
      waybar
      rofi-wayland
      swaybg # still needed for wallpapers unless waybar/rofi handles it
    ];
  };
}
