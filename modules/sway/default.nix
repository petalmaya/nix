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

  # osConfig carries NixOS options; config.osConfig does not exist.
  liveSway =
    if osConfig != null then
      osConfig.nixtop.dev.liveSway or false
    else
      config.nixtop.dev.liveSway or false;
  livePath = "${config.home.homeDirectory}/nix/modules/sway/sway";

  # Waybar symlinks only `config`; style.css is matugen-owned and must stay writable.
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
  # Per-user shell; host default, overridable per user.
  shell = config.nixtop.shell;
  useWaybar = swayBar == "waybar" && shell == "none";

  # Noctalia targets swayfx or mango; same HM config either way.
  noctaliaCompositor = config.nixtop.noctalia.compositor or "sway";

  # Single source: modules/sway/variants/<name>.conf. Only the JES
  # include path differs (store vs live) and is substituted per path.
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
        # Shell variant owns bar and notifications; swayidle + polkit still needed.
        exec_always --no-startup-id swayidle -w timeout 300 "$lock" timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' before-sleep "$lock"
        exec ~/.local/bin/start-polkit
      ''
    else
      builtins.readFile ./sway/autostart.conf;

  # JES keybinds are included from variant.conf.
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
      xdg = {
        portal = {
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

        # Companion configs; waybar/style.css is matugen-owned, never HM-managed.
        configFile."fuzzel/fuzzel.ini".source = fuzzelSrc + "/fuzzel.ini";
        configFile."swaylock/config".source = swaylockSrc + "/config";
      };

      home = {
        packages =
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
          ++ lib.optionals useWaybar [ waybar ];

        # Used by sway/autostart.conf; outside ~/.config/sway so it works store-built and live.
        file.".local/bin/start-polkit" = {
          executable = true;
          text = ''
            #!/bin/sh
            exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
          '';
        };

        # Ensure scripts are executable even when live (mkOutOfStoreSymlink keeps perms)
        activation = {
          ensureSwayScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD chmod +x "$HOME/.config/sway/scripts/"* 2>/dev/null || true
          '';

          # Matugen-owned outputs must exist and stay writable.
          ensureSwayThemeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

          # Live variant copies the same single-source file the store build reads.
          # Skip when the symlink dangles; the fix is cloning the repo to ~/nix.
          ensureSwayLiveVariant = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ "${if liveSway then "1" else "0"}" = "1" ]; then
              if [ -d "$HOME/.config/sway" ]; then
                $DRY_RUN_CMD rm -f "$HOME/.config/sway/variant.conf" || true
                if $DRY_RUN_CMD cp "${./variants}/${variantName}.conf" "$HOME/.config/sway/variant.conf"; then
                  ${lib.optionalString (shell == "jes") ''
                    # JES include differs by path only: store dir vs live checkout.
                    $DRY_RUN_CMD sed -i "s|@jesKeybinds@|$HOME/nix/modules/shell/jes/sway/keybinds.conf|" "$HOME/.config/sway/variant.conf"
                  ''}
                  : # no-op: bash rejects an empty then-branch when the JES sed above is compiled out
                else
                  echo "WARNING: cannot write $HOME/.config/sway/variant.conf (dir owner: $(stat -c %U "$HOME/.config/sway"), you: $(whoami)); leaving the old one, sway keeps stale keybinds" >&2
                  echo "WARNING: fix with: sudo chown -R $(whoami) $HOME/.config/sway $HOME/nix  (then rebuild)" >&2
                fi
              else
                echo "liveSway is on but $HOME/.config/sway is a dangling symlink: clone the repo to $HOME/nix (or disable nixtop.dev.liveSway); leaving variant.conf alone" >&2
              fi
            fi
          '';
        };
      };
    })

    (lib.mkIf (config.nixtop.sway.enable && !liveSway) {
      xdg.configFile."sway".source = swayConfig;
      xdg.configFile."sway".recursive = true;
    })

    (lib.mkIf (config.nixtop.sway.enable && liveSway) {
      xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink livePath;
      xdg.configFile."sway".recursive = true;
    })

    # Mako colors arrive via include from runtime state, never written here.
    (lib.mkIf (config.nixtop.sway.enable && !liveMako) {
      xdg.configFile."mako".source = makoSrc;
      xdg.configFile."mako".recursive = true;
    })

    (lib.mkIf (config.nixtop.sway.enable && liveMako) {
      xdg.configFile."mako".source = config.lib.file.mkOutOfStoreSymlink liveMakoPath;
      xdg.configFile."mako".recursive = true;
    })

    # Waybar config is always present; the package itself stays conditional.
    (lib.mkIf (config.nixtop.sway.enable && !liveWaybar) {
      xdg.configFile."waybar/config".source = waybarConfig + "/config";
    })

    (lib.mkIf (config.nixtop.sway.enable && liveWaybar) {
      # Per-file exception: a dir symlink would redirect matugen-owned style.css into the repo.
      xdg.configFile."waybar/config".source = config.lib.file.mkOutOfStoreSymlink liveWaybarPath;
    })
  ];
}
