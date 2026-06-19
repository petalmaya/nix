{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.noctaniri.enable {
  programs.niri = {
    enable = true;
    config = ''
      // Base Niri configuration
      ${builtins.readFile ./config.kdl}

      // Dynamic/Nix-specific extra options
      spawn-at-startup "sh" "-c" "dbus-update-activation-environment --systemd --all"
      // spawn-at-startup "swaybg" "-i" "${inputs.self}/assets/wallpaper/cute_bg.png" "-m" "fill"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "sh" "-c" "dbus-update-activation-environment --systemd --all && exec noctalia"

      // XWayland satellite configuration
      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }
    '';
  };

  # swayosd works under niri (Should doestn idk why who knows lol!)
  services.swayosd.enable = true;

  home.packages = with pkgs; [
    swaybg
    swaylock
    grim
    slurp
    mako
    xwayland-satellite
  ];
}
