{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  cfg = config.nixtop.quickshell;
  active = config.nixtop.shell == "quickshell";

  shellPkg = pkgs.callPackage ./package.nix { };

  liveQuickshell =
    if osConfig != null then
      osConfig.nixtop.dev.liveQuickshell or false
    else
      config.nixtop.dev.liveQuickshell or false;
  livePath = "${config.home.homeDirectory}/nix/modules/shell/quickshell/shell";
in
{
  options.nixtop.quickshell.enable = lib.mkOption {
    type = lib.types.bool;
    default = active;
    description = "Enable the nixtop-shell Quickshell config. Follows nixtop.shell when unset.";
  };
  options.nixtop.quickshell.compositor = lib.mkOption {
    type = lib.types.enum [
      "sway"
      "mango"
    ];
    default = "mango";
    description = "Which compositor nixtop-shell targets.";
  };

  config = lib.mkIf (cfg.enable && active) {
    # shellPkg already wraps pkgs.quickshell, so don't list it separately.
    home = {
      packages = [
        shellPkg
        pkgs.jq
      ];

      file.".config/nixtop-shell" = lib.mkIf liveQuickshell {
        source = config.lib.file.mkOutOfStoreSymlink livePath;
      };

      # Quickshell falls back to ~/.config/quickshell, so keep it as a compat
      # symlink to the real config dir.
      activation.ensureQuickshellCompat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/nixtop-shell" "$HOME/.cache/nixtop-shell"
        $DRY_RUN_CMD [ -e "$HOME/.config/quickshell" ] || $DRY_RUN_CMD ln -s "$HOME/.config/nixtop-shell" "$HOME/.config/quickshell" 2>/dev/null || true
        $DRY_RUN_CMD chmod +x "$HOME/.config/nixtop-shell/scripts/"* 2>/dev/null || true
      '';
    };

    xdg.configFile."nixtop-shell" = lib.mkIf (!liveQuickshell) {
      source = ./shell;
      recursive = true;
    };

    assertions = [
      {
        assertion = !(config.nixtop.noctalia.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both noctalia and quickshell";
      }
      {
        assertion = !(config.nixtop.jes.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both jes and quickshell";
      }
      {
        assertion = cfg.compositor == "sway" || cfg.compositor == "mango";
        message = "nixtop.quickshell.compositor must be mango or sway";
      }
    ];
  };
}
