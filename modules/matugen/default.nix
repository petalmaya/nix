{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  cfg = config.nixtop.services.matugen;

  # All matugen templates. To add one: drop the source under ./templates/
  # and register its input path, output path, and optional reload hook below.
  # (mango is archived — the sway session themes via the sway template.)
  templates = {
    noctalia = {
      input_path = "noctalia/palette.json";
      output_path = "~/.config/noctalia/palettes/nixtop.json";
      post_hook = "noctalia msg reload 2>/dev/null || true";
    };
    jes = {
      # JES watches ~/.local/state/JES_colors.json live (shell.qml FileView)
      input_path = "jes/colors.json";
      output_path = "~/.local/state/JES_colors.json";
    };
    mango = {
      input_path = "mango/mango.conf";
      output_path = "~/.local/state/nixtop/theme/mango.conf";
      post_hook = "mmsg dispatch reload_config 2>/dev/null || true";
    };
    sway = {
      input_path = "sway/sway";
      output_path = "~/.local/state/nixtop/theme/sway";
      post_hook = "bash ~/.config/matugen/templates/sway/apply.sh 2>/dev/null || true";
    };
    waybar = {
      input_path = "waybar/style.css";
      # matugen-owned writable file (HM must NOT manage this path: a store
      # symlink here is read-only and every run would fail). Seeded once from
      # modules/sway/waybar/style.css by the sway module's activation.
      output_path = "~/.config/waybar/style.css";
      post_hook = "bash ~/.config/matugen/templates/waybar/apply.sh 2>/dev/null || true";
    };
    fuzzel = {
      input_path = "fuzzel/fuzzel.conf";
      output_path = "~/.config/fuzzel/themes/generated";
      post_hook = "bash ~/.config/matugen/templates/fuzzel/apply.sh 2>/dev/null || true";
    };
    mako = {
      input_path = "mako/config";
      # Colors only; merged over the static config via mako's `include=`
      # (see modules/sway/mako/config), so this stays writable state.
      output_path = "~/.local/state/nixtop/theme/mako";
      post_hook = "bash ~/.config/matugen/templates/mako/apply.sh 2>/dev/null || true";
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
    "papirus-icons" = {
      input_path = "papirus-icons/colors";
      # State, not templates: matugen cannot write back into its own
      # read-only template source (that failure aborted whole runs).
      output_path = "~/.local/state/nixtop/theme/papirus-colors";
      post_hook = "bash ~/.config/matugen/templates/papirus-icons/apply.sh 2>/dev/null || true";
    };
  };

  # Per-app theming ownership (nixtop.theme.owner / nixtop.theme.apps) is
  # parked: Noctalia does not theme these apps yet, so matugen owns every
  # template. The options stay so existing configs keep evaluating; gate the
  # registry here again if Noctalia ever takes over an app.
  enabledTemplates = lib.filterAttrs (name: _: cfg.templates.${name}.enable or true) templates;

  matugenConfig = {
    config = {
      prefer = "saturation";
      source_color_index = 0;
    };
    templates = lib.mapAttrs (
      name: t:
      {
        input_path = "${./templates}/${t.input_path}";
        output_path = t.output_path;
      }
      // lib.optionalAttrs (t ? post_hook) { post_hook = t.post_hook; }
    ) enabledTemplates;
  };

  # Live template dir – a single symlink when live-editing templates.
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
  options.nixtop.services.matugen.templates = lib.genAttrs (builtins.attrNames templates) (
    name:
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
    }
  );

  # Reserved theming-owner options (see the parked-gating note above).
  options.nixtop.theme.owner = lib.mkOption {
    type = lib.types.enum [
      "auto"
      "matugen"
      "noctalia"
    ];
    default = "auto";
    description = "Who owns app theming. auto follows nixtop.shell.";
  };
  options.nixtop.theme.apps = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.enum [
        "matugen"
        "noctalia"
      ]
    );
    default = { };
    description = "Per-app override for theming owner.";
  };

  config = lib.mkIf cfg.enable (
    let
      # HM modules read NixOS options via the osConfig module argument;
      # config.osConfig does not exist.
      liveMatugen =
        if osConfig != null then
          osConfig.nixtop.dev.liveMatugen or false
        else
          config.nixtop.dev.liveMatugen or false;
    in
    {
      home.packages = with pkgs; [
        matugen
        jq
      ];

      # config.toml is generated at build time from the registry above.
      # There is intentionally no checked-in config file to drift out of sync.
      xdg.configFile."matugen/config.toml".source =
        (pkgs.formats.toml { }).generate "matugen-config.toml"
          matugenConfig;

      # Template sources: store paths by default, one live repo symlink with liveMatugen.
      home.file =
        (
          lib.mkIf (!liveMatugen) {
            ".config/matugen/templates".source = ./templates;
            ".config/matugen/templates".recursive = true;
          }
          // lib.mkIf liveMatugen {
            ".config/matugen/templates".source = config.lib.file.mkOutOfStoreSymlink liveTemplatePath;
          }
        )
        // {
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
              # Live-reload everything matugen just rewrote. Each nudge is
              # best-effort: only the running compositor/shell picks it up.
              if pgrep -x sway >/dev/null 2>&1; then
                    swaymsg reload 2>/dev/null || true
                  fi
                  if pgrep -x waybar >/dev/null 2>&1; then
                    pkill -SIGUSR2 waybar 2>/dev/null || true
                  fi
                  if pgrep -x mako >/dev/null 2>&1; then
                    makoctl reload 2>/dev/null || true
                  fi
              if command -v noctalia >/dev/null 2>&1; then
                noctalia msg reload 2>/dev/null || true
              fi
              mmsg dispatch reload_config 2>/dev/null || true
                  echo "themed from $IMG"
            '';
          };
        };

      # Seed theme output dirs/files so the first matugen run (and the shells
      # watching its outputs) never hits a missing path.
      home.activation.ensureThemeOutputDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/noctalia/palettes"
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/nixtop/theme"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/nixtop-shell"
        $DRY_RUN_CMD [ -e "$HOME/.config/noctalia/palettes/nixtop.json" ] || $DRY_RUN_CMD touch "$HOME/.config/noctalia/palettes/nixtop.json"
      '';

      # papirus-folders recolors the icon theme in place, which needs a writable
      # copy — a store path won't do. Seed one from nixpkgs on first activation.
      home.activation.ensurePapirusIconsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p "$HOME/.local/share/icons"
          if [ ! -d "$HOME/.local/share/icons/Papirus" ]; then
            $DRY_RUN_CMD cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus" "$HOME/.local/share/icons/Papirus"
            $DRY_RUN_CMD chmod -R u+w "$HOME/.local/share/icons/Papirus"
            $DRY_RUN_CMD chmod +x "$HOME/.local/share/icons/Papirus" 2>/dev/null || true
          fi
        # Template hook scripts lose their exec bit through the store/live paths.
        $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/papirus-icons/papirus-folders" 2>/dev/null || true
        $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/papirus-icons/apply.sh" 2>/dev/null || true
        $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/sway/apply.sh" 2>/dev/null || true
          $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/waybar/apply.sh" 2>/dev/null || true
          $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/fuzzel/apply.sh" 2>/dev/null || true
          $DRY_RUN_CMD chmod +x "$HOME/.config/matugen/templates/mako/apply.sh" 2>/dev/null || true
      '';
    }
  );
}
