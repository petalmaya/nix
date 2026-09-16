{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  swaySrc = ./sway;
  fuzzelSrc = ./fuzzel;
  makoSrc = ./mako;
  swaylockSrc = ./swaylock;
  waybarSrc = ./waybar;

  # HM modules read NixOS options via the osConfig module argument;
  # config.osConfig does not exist.
  liveSway =
    if osConfig != null then
      osConfig.nixtop.dev.liveSway or false
    else
      config.nixtop.dev.liveSway or false;
  livePath = "${config.home.homeDirectory}/nix/modules/sway/sway";

  # bar selection — NixOS option, HM reads via osConfig
  swayBar =
    if osConfig != null then
      osConfig.nixtop.sway.bar or "waybar"
    else
      config.nixtop.sway.bar or "waybar";
  shell = if osConfig != null then osConfig.nixtop.shell or "none" else config.nixtop.shell or "none";
  useWaybar = swayBar == "waybar" && shell == "none";

  # Noctalia targets swayfx or mango (nixtop.noctalia.compositor). Same HM
  # config, so read it directly — no osConfig round-trip needed.
  noctaliaCompositor = config.nixtop.noctalia.compositor or "sway";

  # Variant handling: sway's autostart/variant adapt to nixtop.shell + nixtop.sway.bar
  variantConf = pkgs.writeText "sway-variant.conf" (
    if shell == "noctalia" && noctaliaCompositor == "sway" then
      ''
        # Noctalia on swayfx: autostart the shell here with its IPC binds.
        exec noctalia
        set $ipc noctalia msg
        bindsym $mod+space exec $ipc panel-toggle launcher
        bindsym $mod+s exec $ipc panel-toggle control-center
        bindsym $mod+comma exec $ipc settings-toggle
        bindsym --locked XF86AudioRaiseVolume exec $ipc volume-up
        bindsym --locked XF86AudioLowerVolume exec $ipc volume-down
        bindsym --locked XF86AudioMute exec $ipc volume-mute
        bindsym --locked XF86MonBrightnessUp exec $ipc brightness-up
        bindsym --locked XF86MonBrightnessDown exec $ipc brightness-down
      ''
    else if shell == "noctalia" then
      ''
        # Noctalia on mango: the mango session autostarts it
        # (modules/mango/variants/noctalia/autostart.conf), so sway stays empty.
      ''
    else if shell == "quickshell" then
      ''
        # Quickshell variant — swayfx + nixtop-shell (Go IPC daemon, sway-native)
        exec nixtop-shell
        # quickshell IPC binds (launcher/notch)
        bindsym $mod+space exec qs ipc call launcher toggle
        bindsym $mod+Shift+space exec qs ipc call notch hello
        bindsym $mod+n exec qs ipc call notch toggle
        bindsym $mod+m exec qs ipc call notch media
        bindsym $mod+w exec qs ipc call notch workspaces
      ''
    else if shell == "jes" then
      ''
        # JES variant — swayfx + Just Enough Shell (vendored fork, modules/jes)
        exec jes-cli start-daemon
        include ~/.config/sway/jes-keybinds.conf
      ''
    else
      ''
        # Waybar variant (default, shell == none) — no extra autostart; waybar is in autostart.conf
      ''
  );

  autostartVariant =
    if shell == "noctalia" || shell == "quickshell" || shell == "jes" then
      ''
        # Autostart — shell variant owns the bar AND notifications, so waybar AND mako are NOT autostarted here.
        # swayidle + polkit are still needed for all shells.
        exec_always --no-startup-id swayidle -w timeout 300 "$lock" timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' before-sleep "$lock"
        exec ~/.local/bin/start-polkit
      ''
    else
      builtins.readFile ./sway/autostart.conf;

  # JES keybinds file — copied as jes-keybinds.conf, included from variant.conf
  jesKeybinds = ../jes/sway/keybinds.conf;

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
    cat > $out/autostart.conf <<'AUTOSTART'
    ${autostartVariant}
    AUTOSTART
    cat ${variantConf} > $out/variant.conf
    cp ${jesKeybinds} $out/jes-keybinds.conf
    mkdir -p $out/scripts
    cp ${swaySrc}/scripts/* $out/scripts/
    chmod +x $out/scripts/*
  '';

  waybarConfig = pkgs.runCommand "waybar-config" { } ''
    mkdir -p $out
    cp ${waybarSrc}/config.jsonc $out/config
    cp ${waybarSrc}/style.css $out/style.css
  '';
in
{
  options.nixtop.sway.enable = lib.mkEnableOption "Sway window manager (swayfx)";

  config = lib.mkMerge [
    (lib.mkIf config.nixtop.sway.enable {
      xdg.portal = {
        enable = lib.mkDefault true;
        xdgOpenUsePortal = true;
        config.sway = {
          default = [
            "gtk"
            "gnome"
          ];
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

      home.packages =
        with pkgs;
        [
          swaybg
          jq
          swaylock
          swayidle
          grim
          slurp
          wl-clipboard
          fuzzel
          foot
          pamixer
          brightnessctl
          playerctl
          libnotify
          polkit_gnome
        ]
        ++ lib.optionals (shell == "none") [ mako ]
        ++ lib.optionals useWaybar [ waybar ]
        ++ [
          # retained for fallback scripts; waybar now provides the bar, so ip/ping/pactl are optional
          iproute2
          iputils
          gawk
          coreutils
          pulseaudio # provides pactl (pipewire-pulse compat)
        ];

      # Companion configs – fuzzel, mako, swaylock, waybar
      xdg.configFile."fuzzel/fuzzel.ini".source = fuzzelSrc + "/fuzzel.ini";
      xdg.configFile."mako/config".source = makoSrc + "/config";
      xdg.configFile."swaylock/config".source = swaylockSrc + "/config";
      # waybar — static fallback; matugen overwrites style.css live at ~/.config/waybar/style.css
      # Config is always present so `matugen` can template it even when bar is disabled; package is conditional on useWaybar
      xdg.configFile."waybar/config".source = waybarConfig + "/config";
      xdg.configFile."waybar/style.css".source = waybarConfig + "/style.css";

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
        # status.sh archived (waybar replaces it); keep executable if present for manual use
        $DRY_RUN_CMD chmod +x "$HOME/.config/sway/status.sh" 2>/dev/null || true
      '';

      # Ensure matugen theme dirs exist before first `matugen image` (sway + waybar)
      home.activation.ensureSwayThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/waybar"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/fuzzel/themes"
        $DRY_RUN_CMD [ -e "$HOME/.local/state/nixtop/theme/sway" ] || $DRY_RUN_CMD touch "$HOME/.local/state/nixtop/theme/sway"
        $DRY_RUN_CMD [ -e "$HOME/.config/waybar/style.css" ] || $DRY_RUN_CMD touch "$HOME/.config/waybar/style.css"
        $DRY_RUN_CMD [ -e "$HOME/.config/fuzzel/themes/generated" ] || $DRY_RUN_CMD touch "$HOME/.config/fuzzel/themes/generated"
      '';

      # Live variant: with liveSway, ~/.config/sway is a symlink into the repo,
      # so the store-built variant.conf is not used. This refreshes the live
      # variant file to match nixtop.shell (swaymsg reload picks it up).
      #
      # Never mkdir ~/.config/sway here: it is a symlink, and writing through
      # a dangling one (no ~/nix checkout) aborts activation — while HM
      # recreates the link every run, so deleting it cannot help either.
      # Skip with a warning instead; the fix is cloning the repo to ~/nix.
      home.activation.ensureSwayLiveVariant = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ "${if liveSway then "1" else "0"}" = "1" ]; then
          if [ -d "$HOME/.config/sway" ]; then
            if [ "${shell}" = "noctalia" ] && [ "${noctaliaCompositor}" = "sway" ]; then
              $DRY_RUN_CMD cat > "$HOME/.config/sway/variant.conf" <<'VARIANT'
        exec noctalia
        set $ipc noctalia msg
        bindsym $mod+space exec $ipc panel-toggle launcher
        bindsym $mod+s exec $ipc panel-toggle control-center
        bindsym $mod+comma exec $ipc settings-toggle
        VARIANT
            elif [ "${shell}" = "noctalia" ]; then
              # noctalia targets mango: mango autostart owns it, sway variant stays empty
              $DRY_RUN_CMD cat > "$HOME/.config/sway/variant.conf" <<'VARIANT'
        # noctalia on mango (see modules/mango/variants/noctalia/)
        VARIANT
            elif [ "${shell}" = "quickshell" ]; then
              $DRY_RUN_CMD cat > "$HOME/.config/sway/variant.conf" <<'VARIANT'
        exec nixtop-shell
        bindsym $mod+space exec qs ipc call launcher toggle
        VARIANT
            elif [ "${shell}" = "jes" ]; then
              # live checkout: ~/.config/sway IS the repo dir, so include jes keybinds by repo path
              $DRY_RUN_CMD cat > "$HOME/.config/sway/variant.conf" <<'VARIANT'
        exec jes-cli start-daemon
        include ~/nix/modules/jes/sway/keybinds.conf
        VARIANT
            else
              $DRY_RUN_CMD cat > "$HOME/.config/sway/variant.conf" <<'VARIANT'
        # waybar-only (shell == none)
        VARIANT
            fi
          else
            echo "liveSway is on but $HOME/.config/sway is a dangling symlink: clone the repo to $HOME/nix (or disable nixtop.dev.liveSway); leaving variant.conf alone" >&2
          fi
        fi
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
