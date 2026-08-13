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
  # `qs ipc call ...` binds further down are now LEFT AS-IS (no `-c`
  # patched in): ../package.nix's wrapper launches bare `qs`, which
  # resolves ~/.config/quickshell (symlinked in ../default.nix) and
  # registers under the default instance name - exactly what a bare
  # `qs ipc call ...` with no `-c` already targets. The old manifest
  # scheme this was compensating for is gone.
  rawConfig = builtins.readFile "${dotsNiriDir}/config.kdl";
  patchedConfig = builtins.replaceStrings
    [
      ''spawn-at-startup "quickshell"''
      ''spawn-at-startup "/usr/libexec/polkit-kde-authentication-agent-1"''
      ''spawn "quickshell" "ipc" "call" "lockscreen" "lock";''
    ]
    [
      ''spawn-at-startup "${kurukurubar}/bin/kurukurubar"''
      ''spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"''
      ''spawn "qs" "ipc" "call" "lockscreen" "lock";''
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
