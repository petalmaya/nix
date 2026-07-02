{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.pureniri.enable {
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

  # Write the additional configuration files needed by Niri-Nix-Noctalia
  xdg.configFile."niri/noctalia.kdl".text = builtins.readFile ./noctalia.kdl;
  xdg.configFile."niri/dms/binds.kdl".text = builtins.readFile ./binds.kdl;

  home.packages = with pkgs; [
    swaybg
    swaylock
    grim
    slurp
    mako
    xwayland-satellite
  ];
}
