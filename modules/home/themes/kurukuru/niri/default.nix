{ pkgs, lib, config, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  kurukurubar = import ../package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
  dotsNiriDir = "${inputs.self}/assets/dots/kurukuru/niri";

  # Vendored (assets/dots/kurukuru/niri/config.kdl) from dotsquick, written
  # for Alice's Debian machine - it spawns bare `quickshell` (assumes a
  # manually-copied ~/.config/quickshell) and a Debian-path polkit agent.
  # Swap both for the NixOS-native equivalents - the packaged `kurukurubar`
  # binary (already embeds the right `-c kurukurubar` flag, see
  # ../package.nix) and polkit_gnome, matching what noctaniri/niri used.
  # Everything else (outputs, binds, layer-rules, includes) is untouched
  # from dotsquick.
  #
  # The `qs ipc call ...` binds further down also need patching: bare
  # `qs ipc call` targets the config named "default" (see qs(1)), but
  # kurukurubar registers itself under the name "kurukurubar" (see
  # ../package.nix's manifest) - so every bind needs `-c kurukurubar`
  # added, or it silently finds no instance to talk to. There's also one
  # stray `quickshell ipc call lockscreen lock` bind that was never
  # touched for this fork at all: `quickshell` isn't the binary name here
  # (`qs` is, per ../package.nix's `getExe`), so that bind was failing to
  # spawn anything, full stop.
  rawConfig = builtins.readFile "${dotsNiriDir}/config.kdl";
  patchedConfig = builtins.replaceStrings
    [
      ''spawn-at-startup "quickshell"''
      ''spawn-at-startup "/usr/libexec/polkit-kde-authentication-agent-1"''
      ''spawn "qs" "ipc" "call"''
      ''spawn "quickshell" "ipc" "call" "lockscreen" "lock";''
    ]
    [
      ''spawn-at-startup "${kurukurubar}/bin/kurukurubar"''
      ''spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"''
      ''spawn "qs" "-c" "kurukurubar" "ipc" "call"''
      ''spawn "qs" "-c" "kurukurubar" "ipc" "call" "lockscreen" "lock";''
    ]
    rawConfig;
in
lib.mkIf config.nixtop.themes.kurukuru.enable {
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${system}.niri-unstable;
    config = ''
      ${patchedConfig}

      spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"

      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }
    '';
  };

  # config.kdl's `include "animations.kdl"` / `include "flutterice.kdl"`
  # resolve relative to ~/.config/niri, so those two need to actually be
  # files there too, not folded into the `config` string above. Straight
  # from the vendored copy, unmodified - flutterice.kdl in particular is
  # matugen's own niri template *output*, kept live once matugen re-runs
  # on wallpaper change (see flutterquick's scripts/applyMatugen.sh and
  # this theme's `programs.matugen.templates.niri`).
  xdg.configFile."niri/animations.kdl".source = "${dotsNiriDir}/animations.kdl";
  xdg.configFile."niri/flutterice.kdl".source = "${dotsNiriDir}/flutterice.kdl";

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
    xwayland-satellite
  ];
}
