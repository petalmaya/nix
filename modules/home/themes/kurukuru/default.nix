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
  kurukurubar = import ./package.nix {
    inherit pkgs;
    quickshellInput = inputs.quickshell;
  };

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

  matugenTemplates = matugenTemplatesRaw;
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
      inputs.matugen.packages.${system}.default
      # dotsquick's own template post_hooks shell out to these -
      # antigravity/apply.sh uses jq, spicetify/apply.sh needs the actual
      # `spicetify` CLI (not added here: it's only useful if you actually
      # run Spotify with spicetify installed, and it wants a real Spotify
      # config dir to patch, not just the binary present - install it
      # yourself if/when you want that template's post_hook to do
      # anything; until then it fails harmlessly, matugen keeps going).
      pkgs.jq
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
    #
    # NOT xdg.configFile (that was a read-only Nix store symlink tree -
    # matugen writes build artifacts back *into* its own templates dir at
    # runtime, e.g. templates/papirus-icons/colors-final, and every one
    # of those writes was failing with "file is Read-Only"). Same
    # writable-real-directory trick already used above for
    # ~/.config/quickshell: symlink to the live git checkout instead of
    # the store, so matugen's writeback lands in a real, writable place.
    home.file.".config/matugen/templates".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/assets/dots/kurukuru/matugen/templates";

    # papirus-icons/apply.sh checks for $HOME/.local/share/icons/Papirus
    # and bails with "Papirus Icons are not installed" if it's missing -
    # that check is written for a normal Linux install where the icon
    # theme's package puts its files there directly. On NixOS,
    # pkgs.papirus-icon-theme instead lands in the read-only store and is
    # made available via /run/current-system/sw/share/icons, which isn't
    # where the script looks, and even a symlink there wouldn't help -
    # apply.sh's papirus-folders step needs to create new symlinks
    # *inside* the theme dir, which a store path can't do. Seed a real,
    # writable copy instead so both the existence check and the later
    # write both succeed.
    home.activation.ensurePapirusIconsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
      if [ ! -d "$HOME/.local/share/icons/Papirus" ]; then
        $DRY_RUN_CMD cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/icons/Papirus"
      fi
    '';

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
