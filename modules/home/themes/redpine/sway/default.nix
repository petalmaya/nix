{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.redpine.enable {
  services.swayosd.enable = true;
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = pkgs.swayfx;
    config = null; # pure file-based config
    extraConfig = ''
      ${builtins.readFile ./config}

      output "*" bg ${inputs.self}/assets/wallpaper/red_bg.jpg fill
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      ${builtins.readFile ./extraConfig.conf}
    '';
  };
}
