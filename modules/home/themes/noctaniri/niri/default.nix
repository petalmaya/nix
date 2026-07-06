{ pkgs, lib, config, inputs, ... }:

lib.mkIf config.nixtop.themes.noctaniri.enable {
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable;
    config = ''
      // Base Niri configuration
      ${builtins.readFile ./config.kdl}

      // Dynamic/Nix-specific extra options
      spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"
      // spawn-at-startup "swaybg" "-i" "${inputs.self}/assets/wallpaper/cute_bg.png" "-m" "fill"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "noctalia"

      // XWayland satellite configuration
      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }
    '';
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.niri = {
      default = [
        "gtk"
        "gnome"
      ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "xdg-desktop-portal-gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "xdg-desktop-portal-gnome" ];
    };
    extraPortals = [
      pkgs.gnome-keyring
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
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
