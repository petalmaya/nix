{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.everforest.enable {
  services.swayosd.enable = true;
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    package = pkgs.swayfx;
    config = null; # Disable Home Manager's default config generation so we can use pure sway config file
    extraConfig = ''
      # Base Sway configuration
      ${builtins.readFile ./config}

      # Dynamic/Nix-specific extra options
      output "*" bg ${inputs.self}/assets/wallpaper/forest_bg.jpg fill
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      # SwayFX effects/settings
      ${builtins.readFile ./extraConfig.conf}
    '';
  };
}
