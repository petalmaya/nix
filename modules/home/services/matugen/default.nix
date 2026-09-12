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
# Template sources live under templates/. Each runtime entry below points
# into that tree, so matugen and its hooks use one checked-in source of truth.
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

  # "~..." = runtime path (passed through), anything else = templates/<path>.
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
    # These directories have child entries below, so they must not also be
    # linked as whole directories (Home Manager would mask the children).
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
    "steam" = "${t}/steam";
    "vscode" = "${t}/vscode";
    "fuzzel-colors.ini" = "${t}/fuzzel-colors.ini";
    "quickshell-config.json" = "${t}/quickshell-config.json";
    "terminal-sequences" = "${t}/terminal-sequences";
    # Template-specific scripts and files are all sourced from the same tree.
    "starship/starship.toml" = "${t}/starship/starship.toml";
    "starship/apply.sh" = "${t}/starship/apply.sh";
    "fastfetch/config.jsonc" = "${t}/fastfetch/config.jsonc";
    "foot/foot" = "${t}/foot/foot";
    "foot/apply.sh" = "${t}/foot/apply.sh";
    "bat/bat.tmTheme" = "${t}/bat/bat.tmTheme";
    "bat/apply.sh" = "${t}/bat/apply.sh";
    "yazi-theme.toml" = "${t}/yazi-theme.toml";
    "emacs/emacs.el" = "${t}/emacs/emacs.el";
    "emacs/apply.sh" = "${t}/emacs/apply.sh";
    "emacs/output-path.sh" = "${t}/emacs/output-path.sh";
    "spicetify/spicetify.ini" = "${t}/spicetify/spicetify.ini";
    "spicetify/apply.sh" = "${t}/spicetify/apply.sh";
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
      type = lib.types.submodule {
        options.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run the '${name}' matugen template.";
        };
      };
      default = { };
      description = "Options for the '${name}' matugen template.";
    });

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.matugen.packages.${system}.default
      pkgs.jq # some apply.sh hooks need it
    ];

    # NOTE: deliberately NOT using inputs.matugen's own `programs.matugen`
    # option here. That module bakes one wallpaper into a build-time Nix
    # derivation and only exposes the resulting colours as a read-only
    # attrset (theme.colors / theme.files) - it never copies rendered
    # templates into $HOME. Our workflow is "run `matugen image <wallpaper>`
    # by hand whenever", so what we actually need Nix to do is just place a
    # real, resolved config.toml where the matugen CLI looks for one by
    # default. matugen does the rendering + post_hooks live, same as it
    # always has.
    home.file = runtimeTree // {
      ".config/matugen/config.toml".source =
        (pkgs.formats.toml { }).generate "matugen-config.toml" {
          config = parsed.config;
          templates = matugenTemplates;
        };
    };

    # HM owns gtk settings.ini; force to heal leftover matugen file.
    xdg.configFile."gtk-3.0/settings.ini".force = true;

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
