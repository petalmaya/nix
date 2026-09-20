# Draft sandbox for jellyfin-mpv-shim. Not imported by home.nix yet.
{
  pkgs,
  inputs,
  ...
}:
let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };
  shim = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = pkgs.jellyfin-mpv-shim;
        flatpak.appId = "com.github.iwalton3.jellyfin-mpv-shim";
        gpu.enable = true;
        fonts.enable = true;
        locale.enable = true;
        dbus.policies = {
          "org.freedesktop.Notifications" = "talk";
        };
        bubblewrap = {
          network = true;
          sockets = {
            wayland = true;
            x11 = true;
            pulse = true;
            pipewire = true;
          };
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.config/jellyfin-mpv-shim")
            (sloth.concat' sloth.homeDir "/.local/share/jellyfin-mpv-shim")
            (sloth.concat' sloth.homeDir "/.cache/jellyfin-mpv-shim")
          ];
        };
      };
  };
in
{
  home.packages = [ shim.config.env ];
}
