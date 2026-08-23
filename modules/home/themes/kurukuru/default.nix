# Kurukuru theme: Niri compositor + Kuru Kuru Bar (Quickshell, personal
# `flutterquick` fork) desktop shell, themed via matugen off vendored
# `dotsquick` config/templates (./foot, ./niri - previously scattered
# under a top-level assets/dots/kurukuru, folded in here so this module
# is self-contained and nothing toggles half of a feature from a file
# no one remembers exists). Matugen itself - both the service that runs
# it and its vendored config.toml/templates data - has since moved out
# to modules/home/services/matugen entirely, since none of it was
# actually kurukuru-specific. Foot's actual `programs.foot` wiring
# lives in modules/home/terminal/foot; ./foot here is just this
# theme's own foot.ini/colors.ini data.
#
# Replaces `themes.noctaniri` (Niri + Noctalia Shell) as the desktop
# shell. The matching login manager swap (Noctalia Greeter -> flutterquick's
# greeter.qml) is NixOS-level, not Home Manager - see
# hosts/common/default.nix.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.kurukuru;
  kurukurubar = import ./package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };
in {
  options.nixtop.themes.kurukuru.enable = lib.mkEnableOption "Kurukuru Theme (Niri + Kuru Kuru Bar / Quickshell)";
  options.nixtop.themes.kurukuru.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Absolute path to your actual git checkout of this flake (not the
      Nix store copy `inputs.self` resolves to). Used to symlink
      ~/.config/quickshell straight into
      ''${repoPath}/modules/home/themes/kurukuru/quickshell, so editing
      QML there takes effect without a rebuild and bare `qs`/`quickshell`
      finds a real config. Only needs changing if you clone this repo
      somewhere other than ~/nix.
    '';
  };

  imports = [
    ./niri
  ];

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      theme = {
        name = "Everforest-Dark-B";
        package = pkgs.everforest-gtk-theme;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.theme = null;
    };

    home.pointerCursor = {
      enable = true; # deprecation: relying on the option's presence to enable it is deprecated as of HM's newer releases
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
    };

    # The real fix for "no ~/.config/quickshell" and "qs can't find
    # shell.qml": an out-of-store symlink straight into your working
    # tree, not a copy into the store. `qs`/`quickshell` run bare now
    # find this directly (see package.nix's rewritten wrapper - it no
    # longer passes -c/-p at all), and edits to the QML here are edits to
    # your actual repo, live, no rebuild loop.
    home.file.".config/quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/themes/kurukuru/quickshell";

    home.packages = [
      kurukurubar
      # flutterquick's own README-listed deps that aren't already covered
      # elsewhere in this repo (fonts.packages in hosts/common only has
      # nerd-fonts.jetbrains-mono + symbols-only, neither of which is what
      # the launcher/glyphs actually want).
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
#     pkgs.librebarcode
    ];

    # Matugen itself (config.toml, the ~/.config/matugen/templates
    # symlink, and the Papirus-writable-copy activation it needs) now
    # lives in modules/home/services/matugen as its own always-on
    # service (nixtop.services.matugen.enable, default true) - it isn't
    # this theme module's to own, it's infrastructure every themed app
    # template depends on regardless of which desktop theme is active.
    # Nothing else needed here for colors.json/flutterice-themed configs
    # to keep working; if nixtop.services.matugen.enable is ever flipped
    # off, re-theming just stops updating and everything runs on
    # whatever was last generated (or the vendored committed fallback).

    # Foot/niri get their real config from the same vendored dotsquick
    # tree - see modules/home/terminal/foot's branch (gated on this same
    # option) and ./niri below.

    # Kuru Kuru Bar's Data/NotifServer.qml implements its own
    # Quickshell.Services.Notifications NotificationServer - i.e. it
    # registers the org.freedesktop.Notifications DBus name itself.
    # alice's home.nix independently flips nixtop.services.mako.enable,
    # which would otherwise race it for that same name (whichever starts
    # first wins, the other just silently stops delivering
    # notifications). Force it off here rather than asking alice to
    # remember to flip it herself - flagged in handoff.md since this is a
    # real, if minor, behavior change for any host enabling this theme.
    services.mako.enable = lib.mkForce false;
  };
}
