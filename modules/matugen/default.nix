{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.nixtop.services.matugen;

  # Registry – one place to add/remove a template (§8.5)
  # Keep-list (11): noctalia (palette bridge), mango, quickshell, foot, gtk3, gtk4, bat, starship, fastfetch, yazi, emacs
  templates = {
    noctalia = {
      input_path = "noctalia/palette.json";
      output_path = "~/.config/noctalia/palettes/nixtop.json";
      # Noctalia watches this file; nudge it to reload if the CLI exists
      post_hook = "noctalia msg reload 2>/dev/null || true";
    };
    mango = {
      input_path = "mango/mango.conf";
      output_path = "~/.local/state/nixtop/theme/mango.conf";
      post_hook = "mmsg dispatch reload_config 2>/dev/null || true";
    };
    quickshell = {
      input_path = "quickshell/quickshell.json";
      output_path = "~/.config/nixtop-shell/colors.json";
    };
    foot = {
      input_path = "foot/foot";
      output_path = "~/.config/foot/themes/generated";
      post_hook = "bash ~/.config/matugen/templates/foot/apply.sh 2>/dev/null || true";
    };
    gtk3 = {
      input_path = "gtk/gtk3.css";
      output_path = "~/.config/gtk-3.0/pinaceae.css";
      post_hook = "bash ~/.config/matugen/templates/gtk/apply.sh dark 2>/dev/null || true";
    };
    gtk4 = {
      input_path = "gtk/gtk4.css";
      output_path = "~/.config/gtk-4.0/pinaceae.css";
      post_hook = "bash ~/.config/matugen/templates/gtk/apply.sh dark 2>/dev/null || true";
    };
    bat = {
      input_path = "bat/bat.tmTheme";
      output_path = "~/.config/bat/themes/pinaceae.tmTheme";
      post_hook = "bash ~/.config/matugen/templates/bat/apply.sh 2>/dev/null || true";
    };
    starship = {
      input_path = "starship/starship.toml";
      output_path = "~/.config/starship.toml";
    };
    fastfetch = {
      input_path = "fastfetch/config.jsonc";
      output_path = "~/.config/fastfetch/config.jsonc";
    };
    yazi = {
      input_path = "yazi/yazi-theme.toml";
      output_path = "~/.config/yazi/theme.toml";
    };
    emacs = {
      input_path = "emacs/emacs.el";
      output_path = "~/.config/emacs/themes/pinaceae-theme.el";
      post_hook = "bash ~/.config/matugen/templates/emacs/apply.sh 2>/dev/null || true";
    };
  };

  # Theming owner switch (§8.3) – determines who writes the file.
  # When owner is noctalia for a given app, matugen's template for that app is disabled.
  # Shell is a NixOS option, so HM reads via osConfig when available.
  shell = if config ? osConfig then config.osConfig.nixtop.shell else config.nixtop.shell or "noctalia";
  themeOwner = config.nixtop.theme.owner or "auto";
  effectiveOwner = app:
    let
      perApp = config.nixtop.theme.apps.${app} or null;
    in
    if perApp != null then perApp
    else if themeOwner == "auto" then (if shell == "noctalia" then "noctalia" else "matugen")
    else themeOwner;

  # Gate matugen templates where noctalia owns the app: foot, gtk3, gtk4, emacs may be owned by noctalia.
  # The list of gateable apps is those where both systems can write the same file.
  isMatugenOwned = name:
    if name == "foot" then effectiveOwner "foot" == "matugen"
    else if name == "gtk3" then effectiveOwner "gtk" == "matugen"
    else if name == "gtk4" then effectiveOwner "gtk" == "matugen"
    else if name == "emacs" then effectiveOwner "emacs" == "matugen"
    else true;

  # Filter templates by enable flags and by owner gating
  enabledTemplates = lib.filterAttrs (name: t:
    (cfg.templates.${name}.enable or true) && isMatugenOwned name
  ) templates;

  matugenConfig = {
    config = {
      prefer = "saturation";
      source_color_index = 0;
    };
    templates = lib.mapAttrs (name: t: {
      input_path = "${./templates}/${t.input_path}";
      output_path = t.output_path;
    } // lib.optionalAttrs (t ? post_hook) { post_hook = t.post_hook; }) enabledTemplates;
  };

  # Live template dir – one symlink when enabled (§8.4)
  liveTemplatePath = "${config.home.homeDirectory}/nix/modules/matugen/templates";
in
{
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
  options.nixtop.services.matugen.templates = lib.genAttrs (builtins.attrNames templates) (name:
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

  # theming owner options (§8.3)
  options.nixtop.theme.owner = lib.mkOption {
    type = lib.types.enum [ "auto" "matugen" "noctalia" ];
    default = "auto";
    description = "Who owns app theming. auto follows nixtop.shell.";
  };
  options.nixtop.theme.apps = lib.mkOption {
    type = lib.types.attrsOf (lib.types.enum [ "matugen" "noctalia" ]);
    default = { };
    description = "Per-app override for theming owner.";
  };

  config = lib.mkIf cfg.enable (let
    liveMatugen = if config ? osConfig then config.osConfig.nixtop.dev.liveMatugen else config.nixtop.dev.liveMatugen or false;
  in {
    home.packages = with pkgs; [
      matugen
      jq
    ];

    # generated config.toml – no checked-in file (§8.5)
    xdg.configFile."matugen/config.toml".source =
      (pkgs.formats.toml { }).generate "matugen-config.toml" matugenConfig;

    # template sources – either store or live symlink + helper script (dev flag is NixOS-owned)
    home.file = (
      lib.mkIf (!liveMatugen) {
        ".config/matugen/templates".source = ./templates;
        ".config/matugen/templates".recursive = true;
      } // lib.mkIf liveMatugen {
        ".config/matugen/templates".source = config.lib.file.mkOutOfStoreSymlink liveTemplatePath;
      }
    ) // {
      ".local/bin/nixtop-theme" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail
          IMG="''${1:-}"
          if [ -z "$IMG" ]; then
            echo "usage: nixtop-theme <image>" >&2
            exit 1
          fi
          matugen image "$IMG"
          # nudge Noctalia if available
          if command -v noctalia >/dev/null 2>&1; then
            noctalia msg reload 2>/dev/null || true
          fi
          # reload mango
          mmsg dispatch reload_config 2>/dev/null || true
          echo "themed from $IMG"
        '';
      };
    };

    # ensure noctalia palette dir exists before first matugen run
    home.activation.ensureNoctaliaPaletteDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/noctalia/palettes"
      $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
      $DRY_RUN_CMD mkdir -p "$HOME/.config/nixtop-shell"
      $DRY_RUN_CMD [ -e "$HOME/.config/noctalia/palettes/nixtop.json" ] || $DRY_RUN_CMD touch "$HOME/.config/noctalia/palettes/nixtop.json"
    '';
  });
}
