# Matugen (Material You colour generation from a wallpaper) as its own
# background service, independent of any single theme.
#
# This used to live entirely inside modules/home/themes/kurukuru/default.nix,
# gated behind `nixtop.themes.kurukuru.enable` - meaning matugen only ran
# (and colors.json/flutterice.kdl/etc only got regenerated) if the whole
# kurukuru theme was on, even though nothing about matugen itself is
# kurukuru-specific. Pulled out here so it's a first-class
# `nixtop.services.*` toggle like mako/mpd/flatpak, defaulted ON (not
# `mkEnableOption`'s usual off-by-default) since every currently-shipped
# template set assumes it's running.
#
# The vendored template tree it drives (config.toml + templates/) still
# physically lives under ../../themes/kurukuru/matugen - it's the only
# template set that exists right now (dotsquick's, themed "flutterice"),
# and moving 700K of vendored templates to a new path for a rename alone
# isn't worth the churn. If a second theme ever wants its own matugen
# templates, this is the file to teach a `nixtop.activeTheme`-keyed
# `cases` dispatch (same pattern as terminal/foot/default.nix) - for now
# there's only one case, so pointing straight at it is simpler and no
# less correct.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.services.matugen;
  system = pkgs.stdenv.hostPlatform.system;

  templatesSrcDir = "${inputs.self}/modules/home/themes/kurukuru/matugen";

  # config.toml is the source of truth for what gets themed and how
  # (18-odd app templates + post_hooks) - rather than hand-transcribing
  # that into a second, parallel Nix attrset that can drift out of sync,
  # parse it directly and feed it to matugen's own upstream
  # `programs.matugen.templates` option (module.nix, see
  # https://github.com/InioX/matugen). Only `input_path` needs adjusting:
  # config.toml's own paths are relative to itself ("templates/foot/foot"),
  # matugen's module wants something it can actually open, so those get
  # resolved to the vendored store path.
  parsedMatugenConfig = builtins.fromTOML (builtins.readFile "${templatesSrcDir}/config.toml");
  matugenTemplates = lib.mapAttrs
    (_: t: t // { input_path = "${templatesSrcDir}/${t.input_path}"; })
    parsedMatugenConfig.templates;
in {
  options.nixtop.services.matugen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Matugen (Material You wallpaper-based colour generation) as a
      background service. On by default - unlike most `nixtop.services.*`
      toggles - because it's load-bearing for every theme/app template
      currently vendored under themes/kurukuru/matugen, not an optional
      extra. Flip off if you want to strip it out entirely (e.g. for a
      low-resource host that isn't running any of the themed apps).
    '';
  };
  options.nixtop.services.matugen.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Absolute path to your actual git checkout of this flake (not the
      Nix store copy `inputs.self` resolves to). Used to symlink
      ~/.config/matugen/templates straight into
      ''${repoPath}/modules/home/themes/kurukuru/matugen/templates, so
      editing a template/apply.sh takes effect without a rebuild, and so
      matugen's own writeback into that tree (see comment below) lands
      somewhere writable. Only needs changing if you clone this repo
      somewhere other than ~/nix.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.matugen.packages.${system}.default
      # config.toml's own template post_hooks shell out to these -
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
    # Data/Paths.qml resolves on the shell side - no extra wiring needed,
    # regardless of which theme (if any) is otherwise enabled.
    programs.matugen = {
      enable = true;
      variant = "dark";
      templates = matugenTemplates;
    };

    # Templates' post_hook scripts (e.g. `~/.config/matugen/templates/foot/apply.sh`)
    # are referenced by config.toml as paths *under* ~/.config/matugen,
    # not as store paths - `programs.matugen` itself only manages
    # config.toml, it does NOT place the template/hook tree (see the
    # module's own README: "does NOT automatically symlink the files").
    # So the vendored templates dir still needs linking in separately,
    # for the hooks alone.
    #
    # NOT xdg.configFile (that's a read-only Nix store symlink tree -
    # matugen writes build artifacts back *into* its own templates dir at
    # runtime, e.g. templates/papirus-icons/colors-final, and every one
    # of those writes was failing with "file is Read-Only"). Same
    # writable-real-directory trick used elsewhere in this repo for
    # out-of-store QML/config editing: symlink to the live git checkout
    # instead of the store, so matugen's writeback lands in a real,
    # writable place.
    home.file.".config/matugen/templates".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/themes/kurukuru/matugen/templates";

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
    # write both succeed. This only matters if you're actually using the
    # Papirus icon theme (as kurukuru does) - harmless no-op otherwise.
    home.activation.ensurePapirusIconsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
      if [ ! -d "$HOME/.local/share/icons/Papirus" ]; then
        $DRY_RUN_CMD cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/icons/Papirus"
      fi
    '';
  };
}
