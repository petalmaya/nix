{ pkgs, lib, config, inputs, ... }:
let
  # config.kdl/animations.kdl/flutterice.kdl are vendored siblings of this
  # file now (used to live under a top-level assets/dots/kurukuru/niri -
  # moved in here so the whole kurukuru niri integration is one directory,
  # not this default.nix plus an easy-to-forget sibling tree elsewhere).
  dotsNiriDir = ./.;
in
lib.mkIf config.nixtop.themes.kurukuru.enable {
  # epireyn/niri-flake's programs.niri module (see flake.nix's `niri`
  # input comment for why this isn't Home Manager's own built-in module
  # right now). `config` is niri-flake's option name for what would be
  # `extraConfig` on the built-in module; same raw-KDL-string approach
  # either way.
  # niri-flake's home-manager module writes `config` below into the Nix
  # store and manages ~/.config/niri/config.kdl itself as a symlink to
  # that store path - so config.kdl can't *also* be the out-of-store
  # symlink (home-manager would fight itself over who owns that path).
  # Kept this stub as small as the two things that genuinely need a
  # Nix-computed store path (polkit's libexec path, xwayland-satellite's
  # binary), and moved literally everything else - outputs, binds,
  # layout, window/layer-rules, the other `include`s - into
  # niri/config.kdl proper, `include`d here by a different filename.
  # kurukuru.kdl's own spawns reference "kurukurubar"/"qs" by bare name
  # (resolved via PATH - kurukurubar's already in ../default.nix's
  # home.packages) rather than a store path, so it has zero Nix-specific
  # content left and is safe to out-of-store symlink below, same trick
  # as animations.kdl/flutterice.kdl already used. Result: editing
  # binds/outputs/rules is edit-and-reload (Mod+Shift+C, or niri's own
  # config watcher), never edit-rebuild-see.
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    config = ''
      spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

      xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      }

      include optional=true "kurukuru.kdl"
    '';
  };

  # config.kdl's `include "animations.kdl"` / `include "flutterice.kdl"`
  # resolve relative to ~/.config/niri, so those two need to actually be
  # files there too, not folded into the `extraConfig` string above.
  #
  # animations.kdl is plain, hand-edited config - nothing ever writes to
  # it at runtime - so unlike flutterice.kdl below it's safe to symlink
  # straight into the store... but a store symlink means every edit needs
  # a rebuild to see, same reason quickshell/matugen-templates get the
  # out-of-store treatment in ../default.nix. Same trick here: symlink
  # into the live git checkout instead, so tweaking animation curves is
  # edit-and-see, not edit-rebuild-see.
  home.file.".config/niri/animations.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.kurukuru.repoPath}/modules/home/themes/kurukuru/niri/animations.kdl";

  # The big one - outputs/binds/layout/window-rules/layer-rules, see the
  # comment on `programs.niri.config` above for why this is split out
  # under its own filename instead of just being config.kdl.
  home.file.".config/niri/kurukuru.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.nixtop.themes.kurukuru.repoPath}/modules/home/themes/kurukuru/niri/config.kdl";

  # NOT xdg.configFile (read-only Nix store symlink) - flutterice.kdl is
  # matugen's own live template *output* (programs.matugen.templates.niri),
  # rewritten on every re-theme. A store symlink here silently blocks
  # that writeback the same way it did for foot/themes/flutterice (see
  # ../../terminal/foot/default.nix) - just seed a writable copy of the
  # vendored version so the config.kdl `include` doesn't error before
  # matugen has run once; matugen owns the file after that.
  home.activation.ensureNiriFlutterice = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/niri
    $DRY_RUN_CMD [ -e "$HOME/.config/niri/flutterice.kdl" ] || $DRY_RUN_CMD cp "${dotsNiriDir}/flutterice.kdl" "$HOME/.config/niri/flutterice.kdl"
  '';

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
