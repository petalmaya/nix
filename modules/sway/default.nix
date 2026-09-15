{ config, lib, pkgs, osConfig ? null, ... }:
let
  swaySrc = ./sway;
  fuzzelSrc = ./fuzzel;
  makoSrc = ./mako;
  swaylockSrc = ./swaylock;

  # Build a merged sway config directory (mirrors mango/default.nix pattern)
  # Shared files are copied; generated colors live at runtime path, not here.
  swayConfig = pkgs.runCommand "sway-config" { } ''
    mkdir -p $out
    cp ${swaySrc}/config $out/config
    cp ${swaySrc}/variables.conf $out/variables.conf
    cp ${swaySrc}/appearance.conf $out/appearance.conf
    cp ${swaySrc}/inputs.conf $out/inputs.conf
    cp ${swaySrc}/outputs.conf $out/outputs.conf
    cp ${swaySrc}/bar.conf $out/bar.conf
    cp ${swaySrc}/keybinds.conf $out/keybinds.conf
    cp ${swaySrc}/media.conf $out/media.conf
    cp ${swaySrc}/modes.conf $out/modes.conf
    cp ${swaySrc}/autostart.conf $out/autostart.conf
    # scripts + status.sh
    mkdir -p $out/scripts
    cp ${swaySrc}/scripts/* $out/scripts/
    chmod +x $out/scripts/*
    cp ${swaySrc}/status.sh $out/status.sh
    chmod +x $out/status.sh
  '';

  liveSway =
    if osConfig != null then osConfig.nixtop.dev.liveSway or false
    else if config ? osConfig then config.osConfig.nixtop.dev.liveSway or false
    else config.nixtop.dev.liveSway or false;
  livePath = "${config.home.homeDirectory}/nix/modules/sway/sway";
in
{
  options.nixtop.sway.enable = lib.mkEnableOption "Sway window manager (Alpine Lake split)";

  config = lib.mkMerge [
    (lib.mkIf config.nixtop.sway.enable {
      # xdg portal for sway (mirrors mango portal config but sway variant)
      xdg.portal = {
        enable = lib.mkDefault true;
        xdgOpenUsePortal = true;
        config.sway = {
          default = [ "gtk" "gnome" ];
          "org.freedesktop.impl.portal.Access" = [ "gtk" ];
          "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        };
        extraPortals = lib.mkDefault [
          pkgs.gnome-keyring
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
        ];
      };

      home.packages = with pkgs; [
        swaybg
        jq
        swaylock
        swayidle
        grim
        slurp
        wl-clipboard
        mako
        fuzzel
        foot
        pamixer
        brightnessctl
        playerctl
        libnotify
        polkit_gnome
        # status.sh deps — ensure ip/ping/pactl are present so swaybar never sees "Error reading from status bar"
        iproute2
        iputils
        gawk
        coreutils
        pulseaudio # provides pactl (pipewire-pulse compat)
      ];

      # Companion configs – fuzzel, mako, swaylock
      xdg.configFile."fuzzel/fuzzel.ini".source = fuzzelSrc + "/fuzzel.ini";
      xdg.configFile."mako/config".source = makoSrc + "/config";
      xdg.configFile."swaylock/config".source = swaylockSrc + "/config";

      # polkit agent wrapper — used by sway/autostart.conf via `exec ~/.local/bin/start-polkit`
      # This lives outside ~/.config/sway so it works both store-built and live-symlinked.
      home.file.".local/bin/start-polkit" = {
        executable = true;
        text = ''
          #!/bin/sh
          exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
        '';
      };

      # Ensure scripts are executable even when live (mkOutOfStoreSymlink keeps perms)
      home.activation.ensureSwayScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD chmod +x "$HOME/.config/sway/scripts/"* 2>/dev/null || true
        $DRY_RUN_CMD chmod +x "$HOME/.config/sway/status.sh" 2>/dev/null || true
      '';
    })

    (lib.mkIf (config.nixtop.sway.enable && !liveSway) {
      xdg.configFile."sway".source = swayConfig;
      xdg.configFile."sway".recursive = true;
    })

    (lib.mkIf (config.nixtop.sway.enable && liveSway) {
      xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink livePath;
      xdg.configFile."sway".recursive = true;
    })
  ];
}
