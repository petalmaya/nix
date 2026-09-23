# EWM session (NixOS side). Extra login entry; pair with ./home.nix.
# Upstream: https://codeberg.org/ezemtsov/ewm
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
  # EWM needs its own unstable (Emacs 31.1); our 26.05 set cannot build it.
  ewmFlakePkg = inputs.ewm.packages.${system}.default;
  ewmPkgs = inputs.ewm.inputs.nixpkgs.legacyPackages.${system};

  # Login via ewm-launch; upstream ewm-session fails from a display manager.
  # Shadowing, not replacing: sessionData links sessionPackages with lndir in
  # list order (first file wins), so mkBefore puts ours first.
  ewmLaunchSession =
    pkgs.runCommand "ewm-launch-session"
      {
        passthru.providedSessions = [ "ewm" ];
      }
      ''
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
    services.displayManager.sessionPackages = lib.mkBefore [ ewmLaunchSession ];

    # Pinned to the flake's outputs; defaults would rebuild against 26.05 and fail.
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
      # Full config so consult/hydras work inside EWM; pre-warm once with
      # plain `emacs` after an Elpaca wipe before logging into `ewm`.
    };

    # Cold Elpaca caches can take minutes; don't let systemd kill startup.
    systemd.user.services.ewm.overrideStrategy = "asDropin";
    systemd.user.services.ewm.serviceConfig.TimeoutStartSec = lib.mkDefault "10min";

    environment.systemPackages = with pkgs; [
      wl-clipboard
      brightnessctl
      pamixer
      xwayland-satellite
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = lib.mkDefault cfg.cursorTheme;
      XCURSOR_SIZE = lib.mkDefault (toString cfg.cursorSize);
    };
  };
}
