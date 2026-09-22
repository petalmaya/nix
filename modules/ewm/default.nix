# EWM session (NixOS side). Extra `ewm` login entry next to sway/mango;
# Noctalia and friends stay untouched. Pair with the per-user toggle in
# ./home.nix. Upstream: https://codeberg.org/ezemtsov/ewm
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nixtop.ewm;
  system = pkgs.stdenv.hostPlatform.system;
  # EWM's own unstable (Emacs 31.1, libdisplay-info_0_3); our 26.05 set
  # (Emacs 30.2) can't build it. Everything below comes from the flake,
  # so session and interactive Emacs share one closure (see
  # modules/emacs/default.nix).
  ewmFlakePkg = inputs.ewm.packages.${system}.default;
  ewmPkgs = inputs.ewm.inputs.nixpkgs.legacyPackages.${system};

  # Greeter login via ewm-launch, not ewm-session. Upstream's ewm.desktop
  # runs ewm-session (login-shell re-exec + systemctl --user round-trip
  # into ewm.service), which fails from a display manager; ewm-launch is
  # plain `emacs --fg-daemon --eval "(require 'ewm)" --eval
  # "(ewm-start-module)" (see inputs.ewm nix/service.nix) and works from
  # TTY. It needs nothing beyond normal DM session env: SDDM provides
  # XDG_RUNTIME_DIR/XDG_SESSION_TYPE, WAYLAND_DISPLAY is bound by the
  # compositor itself, and EMACSLOADPATH (for ewm-core.so) comes from the
  # wrapped emacs package below.
  #
  # Shadowing, not replacing: sessionData.desktops links sessionPackages
  # with lndir in list order (first file wins, no buildEnv involved), so
  # mkBefore puts ours first and upstream's duplicate ewm.desktop is
  # skipped. Same filename + DesktopNames=ewm keeps SDDM last-session
  # memory. passthru.providedSessions is required by the sessionPackages
  # option type.
  ewmLaunchSession = pkgs.runCommand "ewm-launch-session" {
    passthru.providedSessions = [ "ewm" ];
  } ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/ewm.desktop <<EOF
    [Desktop Entry]
    Name=ewm
    Comment=Emacs Wayland Manager (direct launch)
    Exec=ewm-launch
    Type=Application
    DesktopNames=ewm
    EOF
  '';
in
{
  imports = [ inputs.ewm.nixosModules.default ];

  options.nixtop.ewm = {
    enable = lib.mkEnableOption "EWM Wayland session (Emacs as compositor, extra login entry)";
    # Session env: EWM reads this before any elisp runs.
    cursorTheme = lib.mkOption {
      type = lib.types.str;
      default = "capitaine-cursors";
      description = "XCURSOR_THEME exported for the EWM session.";
    };
    cursorSize = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "XCURSOR_SIZE exported for the EWM session.";
    };
    withSkia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Experimental Skia GPU Emacs build. Passthrough to programs.ewm.withSkia.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Upstream session entry shadowed: Exec=ewm-launch (see ewmLaunchSession
    # above). Keep the TimeoutStartSec drop-in below for the TTY path until
    # Phase 6 pre-warms the Elpaca cache.
    services.displayManager.sessionPackages = lib.mkBefore [ ewmLaunchSession ];

    # Upstream nix/service.nix provides launcher, ewm.desktop, systemd
    # units, portals. Pinned to the flake's outputs — the defaults would
    # rebuild against our 26.05 pkgs and fail.
    programs.ewm = {
      enable = true;
      package = ewmFlakePkg;
      ewmPackage = ewmFlakePkg;
      # Skia base comes from EWM's own overlay, still outside our pkgs.
      emacsPackage =
        if cfg.withSkia then
          (ewmPkgs.extend inputs.ewm.overlays.default).emacs31-pwayl.pkgs.withPackages (_: [
            ewmFlakePkg
          ])
        else
          ewmPkgs.emacs-pgtk.pkgs.withPackages (_: [ ewmFlakePkg ]);
      inherit (cfg) withSkia;
      # Loads ~/.config/emacs as-is; no --init-directory override needed.
      # Upstream Getting-Started/NixOS wiki uses a minimal init plus
      # --init-directory for the compositor; we intentionally run the full
      # config so consult/hydras work inside EWM. Cost: first boot after
      # an Elpaca wipe downloads MELPA+ELPA and compiles (~3min in the
      # field), which exceeds systemd's default start timeout for the
      # Type=notify ewm.service and looks like "Emacs flashes then back
      # to TTY". Pre-warm once with plain `emacs` before logging into
      # `ewm`, and keep the timeout below generous.
    };

    # Compositor init can take minutes on a cold Elpaca cache; don't let
    # systemd kill ewm.service while Emacs is still starting. Upstream
    # ships the unit via systemd.packages, so override as a drop-in
    # (a plain redefinition here would shadow ExecStart).
    systemd.user.services.ewm.overrideStrategy = "asDropin";
    systemd.user.services.ewm.serviceConfig.TimeoutStartSec = lib.mkDefault "10min";

    # Clipboard plus the media/brightness keys the default bindings use.
    # pamixer matches the repo's sway audio convention (upstream uses wpctl).
    environment.systemPackages = with pkgs; [
      wl-clipboard
      brightnessctl
      pamixer
    ];

    # Must be session env: EWM reads it before any elisp runs.
    environment.sessionVariables = {
      XCURSOR_THEME = lib.mkDefault cfg.cursorTheme;
      XCURSOR_SIZE = lib.mkDefault (toString cfg.cursorSize);
    };
  };
}
