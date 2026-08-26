{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.rosepine-dark.enable {
  services.swayosd.enable = true;
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = pkgs.swayfx;
    config = null; # pure file-based config
    extraConfig = ''
      ${builtins.readFile ./config}

      output "*" bg ${inputs.self}/assets/wallpaper/cute_bg.png fill
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      ${builtins.readFile ./extraConfig.conf}
    '';
  };
}
