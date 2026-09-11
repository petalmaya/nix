# Matugen: wallpaper in, themed configs out. On by default.
#
# Toggles:
#   nixtop.services.matugen.enable             master switch
#   nixtop.services.matugen.templates.<name>.enable
#     one per [templates.<name>] in config.toml, all default true.
#     Off drops that template from matugen's config, so matugen stops
#     writing its output. (Only starship/fastfetch have a static
#     fallback waiting — see terminal/zsh and apps/fetch. For the rest,
#     off just means "don't recolor that app".)
#
# Template sources: most live in templates/, but ones owned by another
# module live next to it as *.temp (see config.toml header). Either way
# they all show up under ~/.config/matugen/templates/ at runtime, so
# post_hook paths never change.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.services.matugen;
  system = pkgs.stdenv.hostPlatform.system;

  # Store path (frozen at build, for programs.matugen) vs live checkout
  # (for runtime links, so template/script edits don't need a rebuild).
  storeRoot = "${inputs.self}";
  liveRoot = cfg.repoPath;
  matugenDir = "${storeRoot}/modules/home/services/matugen";

  # Single registry, parsed straight from config.toml.
  parsed = builtins.fromTOML (builtins.readFile "${matugenDir}/config.toml");
  templateNames = builtins.attrNames parsed.templates;

  # "/modules/..." = repo root (co-located *.temp), "~..." = runtime path
  # (passed through), anything else = templates/<path>.
  resolveInput = p:
    if lib.hasPrefix "/" p then "${storeRoot}${p}"
    else if lib.hasPrefix "~" p then p
    else "${matugenDir}/${p}";

  allTemplates = lib.mapAttrs
    (_: t: t // { input_path = resolveInput t.input_path; })
    parsed.templates;
  matugenTemplates = lib.filterAttrs
    (name: _: cfg.templates.${name}.enable)
    allTemplates;

  # Runtime path -> repo source, all linked under
  # ~/.config/matugen/templates/. Real dir + symlinked files, so matugen
  # can write generated outputs alongside without touching git. Generated
  # outputs (papirus colors-final, cozy/blacklingerie colors.sh) are left
  # out on purpose: matugen creates them in the real dir instead.
  t = "${liveRoot}/modules/home/services/matugen/templates";
  runtimeSources = {
    "antigravity" = "${t}/antigravity";
    "bat" = "${t}/bat";
    "cava" = "${t}/cava";
    "discord" = "${t}/discord";
    "fuzzel" = "${t}/fuzzel";
    "gtk" = "${t}/gtk";
    "lazygit" = "${t}/lazygit";
    "mango" = "${t}/mango";
    "niri" = "${t}/niri";
    "prismlauncher" = "${t}/prismlauncher";
    "pywalfox" = "${t}/pywalfox";
    "pywalfox-beta4" = "${t}/pywalfox-beta4";
    "qt" = "${t}/qt";
    "qutebrowser" = "${t}/qutebrowser";
    "spicetify" = "${t}/spicetify";
    "steam" = "${t}/steam";
    "vscode" = "${t}/vscode";
    "yazi" = "${t}/yazi";
    "fuzzel-colors.ini" = "${t}/fuzzel-colors.ini";
    "quickshell-config.json" = "${t}/quickshell-config.json";
    "terminal-sequences" = "${t}/terminal-sequences";
    # Co-located sources (see config.toml). Runtime names unchanged.
    "starship/starship.toml" = "${liveRoot}/modules/home/terminal/zsh/starship.toml.temp";
    "starship/apply.sh" = "${liveRoot}/modules/home/terminal/zsh/starship-apply.sh";
    "fastfetch/config.jsonc" = "${liveRoot}/modules/home/apps/fetch/config.jsonc.temp";
    "foot/foot" = "${liveRoot}/modules/home/terminal/foot/foot.temp";
    "foot/apply.sh" = "${liveRoot}/modules/home/terminal/foot/foot-apply.sh";
    "bat/bat.tmTheme" = "${liveRoot}/modules/home/terminal/zsh/bat.tmTheme.temp";
    "bat/apply.sh" = "${liveRoot}/modules/home/terminal/zsh/bat-apply.sh";
    "yazi-theme.toml" = "${liveRoot}/modules/home/apps/yazi/yazi-theme.toml.temp";
    "emacs/emacs.el" = "${liveRoot}/modules/home/apps/emacs/emacs.el.temp";
    "emacs/apply.sh" = "${liveRoot}/modules/home/apps/emacs/emacs-apply.sh";
    "emacs/output-path.sh" = "${liveRoot}/modules/home/apps/emacs/emacs-output-path.sh";
    "spicetify/spicetify.ini" = "${liveRoot}/modules/home/apps/spicetify/spicetify.ini.temp";
    "spicetify/apply.sh" = "${liveRoot}/modules/home/apps/spicetify/spicetify-apply.sh";
    "papirus-icons/apply.sh" = "${t}/papirus-icons/apply.sh";
    "papirus-icons/colors" = "${t}/papirus-icons/colors";
    "papirus-icons/papirus-folders" = "${t}/papirus-icons/papirus-folders";
    "papirus-icons/README.md" = "${t}/papirus-icons/README.md";
    "papirus-icons/template.toml" = "${t}/papirus-icons/template.toml";
    "cozy-ui/apply.sh" = "${t}/cozy-ui/apply.sh";
    "cozy-ui/colors-template.sh" = "${t}/cozy-ui/colors-template.sh";
    "cozy-ui/definitions.rpy" = "${t}/cozy-ui/definitions.rpy";
    "cozy-ui/template.toml" = "${t}/cozy-ui/template.toml";
    "blacklingerie/apply.sh" = "${t}/blacklingerie/apply.sh";
    "blacklingerie/colors-template.sh" = "${t}/blacklingerie/colors-template.sh";
    "blacklingerie/template.toml" = "${t}/blacklingerie/template.toml";
    # Manually-seeded pristine sprites (see .gitignore). May dangle on fresh
    # clones — the hook errors the same way it does today until seeded.
    "blacklingerie/originals" = "${t}/blacklingerie/originals";
  };
  runtimeTree = lib.mapAttrs'
    (rel: src: lib.nameValuePair ".config/matugen/templates/${rel}" {
      source = config.lib.file.mkOutOfStoreSymlink src;
    })
    runtimeSources;
in {
  options.nixtop.services.matugen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Master switch for matugen colour generation.";
  };
  options.nixtop.services.matugen.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nix";
    description = "Repo checkout location (runtime template links point here).";
  };
  options.nixtop.services.matugen.templates = lib.genAttrs templateNames (name:
    lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the '${name}' matugen template.";
    });

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.matugen.packages.${system}.default
      pkgs.jq # some apply.sh hooks need it
    ];

    programs.matugen = {
      enable = true;
      variant = "dark";
      # scheme-smart picks the Material variant per wallpaper instead of
      # forcing one: grey images go monochrome, colourful ones vibrant.
      type = "scheme-smart";
      templates = matugenTemplates;
    };

    home.file = runtimeTree;

    # papirus-folders writes inside its theme dir, which a store path can't
    # do — seed a writable copy once.
    home.activation.ensurePapirusIconsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
      if [ ! -d "$HOME/.local/share/icons/Papirus" ]; then
        $DRY_RUN_CMD cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/icons/Papirus"
      fi
    '';
  };
}
