# matugen, wallpaper -> colors for everything. on by default since all the
# vendored templates expect it to be running
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.services.matugen;
  system = pkgs.stdenv.hostPlatform.system;

  templatesSrcDir = "${inputs.self}/modules/home/services/matugen";

  # parse config.toml directly instead of keeping a parallel nix attrset in sync
  parsedMatugenConfig = builtins.fromTOML (builtins.readFile "${templatesSrcDir}/config.toml");
  matugenTemplates = lib.mapAttrs
    (_: t: t // { input_path = "${templatesSrcDir}/${t.input_path}"; })
    parsedMatugenConfig.templates;
in {
  options.nixtop.services.matugen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Matugen colour generation service.
    '';
  };
  options.nixtop.services.matugen.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = ''
      Where this repo is cloned, used for the templates symlink below.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.matugen.packages.${system}.default
      pkgs.jq # some apply.sh hooks need it
    ];

    programs.matugen = {
      enable = true;
      variant = "dark";
      # "scheme-smart" measures the wallpaper's actual colourfulness and
      # picks the Material variant per-image instead of always forcing
      # scheme-tonal-spot: near-grey/monochrome images -> scheme-monochrome
      # (chroma forced to 0 on every palette, so surface/background/accent
      # all stay true neutral grey instead of getting a random tint from
      # whatever stray saturated pixel matugen's scorer picked as source
      # colour), moderately colourful -> scheme-neutral, and colourful
      # photos -> scheme-tonal-spot/vibrant as before.
      type = "scheme-smart";
      templates = matugenTemplates;
    };

    # not xdg.configFile - matugen writes back into this dir at runtime and
    # a store symlink would be read-only. symlink into the repo instead so
    # template edits don't need a rebuild either
    home.file.".config/matugen/templates".source =
      config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/modules/home/services/matugen/templates";

    # papirus-folders needs to write inside the theme dir, which a store
    # path can't do. seed a writable copy (only matters when actually
    # using Papirus, no-op otherwise)
    home.activation.ensurePapirusIconsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
      if [ ! -d "$HOME/.local/share/icons/Papirus" ]; then
        $DRY_RUN_CMD cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/icons/Papirus"
      fi
    '';
  };
}
