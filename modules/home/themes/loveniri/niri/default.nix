{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.loveniri.enable {
  programs.niri = {
    enable = true;
    config = ''
      // Base Niri configuration
      ${builtins.readFile ./config.kdl}

      // Dynamic/Nix-specific extra options
      spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"
      spawn-at-startup "xwayland-satellite"
      spawn-at-startup "swaybg" "-i" "${inputs.self}/assets/wallpaper/cute_bg.png" "-m" "fill"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "noctalia"
    '';
  };

  home.packages = with pkgs; [
    swaybg
    swaylock
    grim
    slurp
    mako
    xwayland-satellite
  ];
}
