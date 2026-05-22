{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.niripine.enable {
  programs.niri = {
    enable = true;
    config = ''
      // Base Niri configuration
      ${builtins.readFile ./config.kdl}

      // Dynamic/Nix-specific extra options
      spawn-at-startup "swaybg" "-i" "${inputs.self}/assets/wallpaper/cute_bg.png" "-m" "fill"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    '';
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
