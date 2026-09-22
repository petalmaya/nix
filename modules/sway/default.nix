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

  # mako/waybar live flags mirror liveSway. mako symlinks the whole dir (its
  # generated colors live in ~/.local/state, included from the static config);
  # waybar symlinks only `config` — style.css is matugen-owned, so symlinking
  # the dir would redirect generated output back into the repo.
  liveMako =
    if osConfig != null then
      osConfig.nixtop.dev.liveMako or false
    else
      config.nixtop.dev.liveMako or false;
  liveMakoPath = "${config.home.homeDirectory}/nix/modules/sway/mako";
  liveWaybar =
    if osConfig != null then
      osConfig.nixtop.dev.liveWaybar or false
    else
      config.nixtop.dev.liveWaybar or false;
  liveWaybarPath = "${config.home.homeDirectory}/nix/modules/sway/waybar/config.jsonc";

  # bar selection — NixOS option, HM reads via osConfig
  swayBar =
    if osConfig != null then
      osConfig.nixtop.sway.bar or "waybar"
    else
      config.nixtop.sway.bar or "waybar";
  # Per-user shell (modules/shell): host default, overridable per user.
  shell = config.nixtop.shell;
  useWaybar = swayBar == "waybar" && shell == "none";

  # Noctalia targets swayfx or mango (nixtop.noctalia.compositor). Same HM
  # config, so read it directly — no osConfig round-trip needed.
  noctaliaCompositor = config.nixtop.noctalia.compositor or "sway";

  # Variant handling: sway's autostart/variant adapt to nixtop.shell + nixtop.sway.bar.
  # Single source: modules/sway/variants/<name>.conf. The store build reads
  # the file; the live activation (ensureSwayLiveVariant below) copies the
  # same file, so store-built and live variant.conf agree. Only the JES
  # include path differs (store dir vs live checkout) and is substituted
  # per path via @jesKeybinds@.
  variantName =
    if shell == "noctalia" && noctaliaCompositor == "sway" then
      "noctalia-sway"
    else if shell == "noctalia" then
      "noctalia-mango"
    else if shell == "quickshell" then
      "quickshell"
    else if shell == "jes" then
      "jes"
    else
      "waybar";
  variantSrc =
    if shell == "jes" then
      pkgs.replaceVars ./variants/jes.conf {
        jesKeybinds = "~/.config/sway/jes-keybinds.conf";
      }
    else
      ./variants/${variantName}.conf;
  variantConf = pkgs.writeText "sway-variant.conf" (builtins.readFile variantSrc);

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
  jesKeybinds = ../shell/jes/sway/keybinds.conf;

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

      # Companion configs – fuzzel, swaylock, mako, waybar.
      # mako/config and waybar/config are static and HM-managed below (store or
      # live); waybar/style.css is NOT here — matugen owns it (see the seed in
      # ensureSwayThemeDir), because an HM store symlink is read-only and every
      # matugen run would fail on it.
      xdg.configFile."fuzzel/fuzzel.ini".source = fuzzelSrc + "/fuzzel.ini";
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
        # status.sh archived (waybar replaces it); keep executable if present for manual use
        $DRY_RUN_CMD chmod +x "$HOME/.config/sway/status.sh" 2>/dev/null || true
      '';

      # Writable theme outputs matugen needs before its first run. style.css is
      # matugen-owned (never HM-managed): seed a writable copy once, and drop
      # the pre-fix store symlink so old checkouts heal.
      home.activation.ensureSwayThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/waybar"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/fuzzel/themes"
        $DRY_RUN_CMD [ -e "$HOME/.local/state/nixtop/theme/sway" ] || $DRY_RUN_CMD touch "$HOME/.local/state/nixtop/theme/sway"
        $DRY_RUN_CMD [ -e "$HOME/.local/state/nixtop/theme/mako" ] || $DRY_RUN_CMD touch "$HOME/.local/state/nixtop/theme/mako"
        $DRY_RUN_CMD [ -e "$HOME/.config/fuzzel/themes/generated" ] || $DRY_RUN_CMD touch "$HOME/.config/fuzzel/themes/generated"
        $DRY_RUN_CMD [ ! -L "$HOME/.config/waybar/style.css" ] || $DRY_RUN_CMD rm "$HOME/.config/waybar/style.css"
        $DRY_RUN_CMD [ -e "$HOME/.config/waybar/style.css" ] || $DRY_RUN_CMD cp "${waybarConfig}/style.css" "$HOME/.config/waybar/style.css"
        $DRY_RUN_CMD chmod u+w "$HOME/.config/waybar/style.css" 2>/dev/null || true
      '';

      # Live variant: with liveSway, ~/.config/sway is a symlink into the repo,
      # so the store-built variant.conf is not used. Copy the same
      # single-source file the store build reads
      # (modules/sway/variants/<name>.conf); swaymsg reload picks it up.
      # The rendered file is git-ignored (it is generated, per-shell).
      #
      # Never mkdir ~/.config/sway here: it is a symlink, and writing through
      # a dangling one (no ~/nix checkout) aborts activation — while HM
      # recreates the link every run, so deleting it cannot help either.
      # Skip with a warning instead; the fix is cloning the repo to ~/nix.
      home.activation.ensureSwayLiveVariant = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ "${if liveSway then "1" else "0"}" = "1" ]; then
          if [ -d "$HOME/.config/sway" ]; then
            $DRY_RUN_CMD cp "${./variants}/${variantName}.conf" "$HOME/.config/sway/variant.conf"
            ${lib.optionalString (shell == "jes") ''
              # JES include differs by path only: store dir vs live checkout.
              $DRY_RUN_CMD sed -i "s|@jesKeybinds@|$HOME/nix/modules/shell/jes/sway/keybinds.conf|" "$HOME/.config/sway/variant.conf"
            ''}
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

    # mako static config — one directory (store or live); colors arrive via
    # `include=~/.local/state/nixtop/theme/mako`, never written here.
    (lib.mkIf (config.nixtop.sway.enable && !liveMako) {
      xdg.configFile."mako".source = makoSrc;
      xdg.configFile."mako".recursive = true;
    })

    (lib.mkIf (config.nixtop.sway.enable && liveMako) {
      xdg.configFile."mako".source = config.lib.file.mkOutOfStoreSymlink liveMakoPath;
      xdg.configFile."mako".recursive = true;
    })

    # waybar config is always present so the bar works even when its package
    # is not installed; the package itself stays conditional on useWaybar.
    (lib.mkIf (config.nixtop.sway.enable && !liveWaybar) {
      xdg.configFile."waybar/config".source = waybarConfig + "/config";
    })

    (lib.mkIf (config.nixtop.sway.enable && liveWaybar) {
      # Deliberate per-file exception (not whole-dir): style.css in the same
      # dir is matugen-owned, so a dir symlink would redirect generated output
      # into the repo. After editing, `pkill -SIGUSR2 waybar` applies it live.
      xdg.configFile."waybar/config".source = config.lib.file.mkOutOfStoreSymlink liveWaybarPath;
    })
  ];
}
