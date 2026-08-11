# Kurukuru theme: Niri compositor + Kuru Kuru Bar (Quickshell, personal
# `flutterquick` fork) desktop shell, themed via matugen off vendored
# `dotsquick` config/templates (assets/dots/kurukuru).
#
# Replaces `themes.noctaniri` (Niri + Noctalia Shell) as the desktop
# shell. The matching login manager swap (Noctalia Greeter -> flutterquick's
# greeter.qml) is NixOS-level, not Home Manager - see
# hosts/common/default.nix.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.themes.kurukuru;
  system = pkgs.stdenv.hostPlatform.system;
  kurukurubar = inputs.flutterquick.packages.${system}.kurukurubar;

  dotsDir = "${inputs.self}/assets/dots/kurukuru";
  matugenDir = "${dotsDir}/matugen";

  # dotsquick's matugen/config.toml is the source of truth for what gets
  # themed and how (18-odd app templates + post_hooks) - rather than
  # hand-transcribing that into a second, parallel Nix attrset that can
  # drift out of sync, parse it directly and feed it to matugen's own
  # upstream `programs.matugen.templates` option (module.nix, see
  # https://github.com/InioX/matugen). Only `input_path` needs adjusting:
  # dotsquick's config.toml uses paths relative to itself
  # ("templates/foot/foot"), matugen's module wants something it can
  # actually open, so those get resolved to the vendored store path.
  parsedMatugenConfig = builtins.fromTOML (builtins.readFile "${matugenDir}/config.toml");
  matugenTemplatesRaw = lib.mapAttrs
    (_: t: t // { input_path = "${matugenDir}/${t.input_path}"; })
    parsedMatugenConfig.templates;

  # `papirus_icons` is the one entry in dotsquick's config.toml whose
  # *output* is also relative-into-the-templates-dir
  # ("templates/papirus-icons/colors-final", a build artifact matugen
  # writes back into its own templates tree at runtime) rather than
  # somewhere under $HOME. Since the templates dir here is a read-only
  # Nix store symlink (see xdg.configFile."matugen/templates" below),
  # that write would fail. Dropped rather than silently left broken -
  # flagged in handoff.md; fixing it properly means giving matugen a
  # writable templates dir just for this one template, which felt like
  # more surgery than this pass was asked to do.
  matugenTemplates = removeAttrs matugenTemplatesRaw [ "papirus_icons" ];
in {
  options.nixtop.themes.kurukuru.enable = lib.mkEnableOption "Kurukuru Theme (Niri + Kuru Kuru Bar / Quickshell)";

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
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 24;
      gtk.enable = true;
    };

    home.packages = [
      kurukurubar
      # flutterquick's own README-listed deps that aren't already covered
      # elsewhere in this repo (fonts.packages in hosts/common only has
      # nerd-fonts.jetbrains-mono + symbols-only, neither of which is what
      # the launcher/glyphs actually want).
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
#     pkgs.librebarcode
      inputs.matugen.packages.${system}.default
    ];

    # Declarative matugen config (writes ~/.config/matugen/config.toml),
    # via the upstream module rather than a raw file copy - see
    # `matugenTemplates` above. `[templates.quickshell]` in there is what
    # writes ~/.config/kurukurubar/colors.json, matching what
    # Data/Paths.qml resolves on the shell side - no extra wiring needed.
    programs.matugen = {
      enable = true;
      variant = "dark";
      templates = matugenTemplates;
    };

    # Templates' post_hook scripts (e.g. `~/.config/matugen/templates/foot/apply.sh`)
    # are referenced by dotsquick's config.toml as paths *under*
    # ~/.config/matugen, not as store paths - `programs.matugen` itself
    # only manages config.toml, it does NOT place the template/hook tree
    # (see the module's own README: "does NOT automatically symlink the
    # files"). So the vendored templates dir still needs linking in
    # separately, for the hooks alone.
    xdg.configFile."matugen/templates" = {
      source = "${matugenDir}/templates";
      recursive = true;
    };

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
