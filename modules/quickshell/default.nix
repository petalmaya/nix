{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  # Per-user shell (modules/shell): host default, overridable per user.
  shell = config.nixtop.shell;
  shellEnabled = shell == "quickshell";
  cfg = config.nixtop.quickshell;

  # build the wrapper (includes Go IPC daemon) from ./package.nix
  swayIpcPkg = pkgs.callPackage ./package.nix {
    quickshellInput = inputs.quickshell;
  };

  liveQuickshell =
    if osConfig != null then
      osConfig.nixtop.dev.liveQuickshell or false
    else
      config.nixtop.dev.liveQuickshell or false;
  livePath = "${config.home.homeDirectory}/nix/modules/quickshell/shell";
in
{
  options.nixtop.quickshell.enable = lib.mkOption {
    type = lib.types.bool;
    default = shellEnabled;
    description = "Enable Alice's own Quickshell (nixtop-shell) on mango/sway. Follows nixtop.shell.";
  };
  options.nixtop.quickshell.compositor = lib.mkOption {
    type = lib.types.enum [
      "sway"
      "mango"
    ];
    default = "mango";
    description = "Which compositor quickshell targets; mango is primary, sway is supported.";
  };

  config = lib.mkIf (cfg.enable && shellEnabled) {
    # MangoWC (Data/MangoWC.qml) is the primary backend via `mmsg watch
    # all-monitors`; Sway stays supported via the Go daemon (Data/Sway.qml).
    # Widgets pick Sway when active, else MangoWC — see WorkspacePill/SystemView.
    home.packages = [
      swayIpcPkg
      pkgs.quickshell
      pkgs.jq
    ];

    # place shell config — store-built or live symlink (mirrors mango/sway live flags)
    xdg.configFile."nixtop-shell" = lib.mkIf (!liveQuickshell) {
      source = ./shell;
      recursive = true;
    };
    home.file.".config/nixtop-shell" = lib.mkIf liveQuickshell {
      source = config.lib.file.mkOutOfStoreSymlink livePath;
    };

    # legacy path: quickshell still resolves ~/.config/quickshell if nixtop-shell missing, so keep a compat symlink
    # Lucid also owns ~/.config/quickshell as a real dir — back it up first
    # so switching lucid -> quickshell does not leave a stale tree behind.
    home.activation.ensureQuickshellCompat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/nixtop-shell"
      $DRY_RUN_CMD mkdir -p "$HOME/.cache/nixtop-shell"
      if [ -d "$HOME/.config/quickshell" ] && [ ! -L "$HOME/.config/quickshell" ]; then
        if [ -e "$HOME/.config/quickshell/lucidprefs/prefs.json" ] || [ -e "$HOME/.config/quickshell/VERSION" ]; then
          $DRY_RUN_CMD mv "$HOME/.config/quickshell" "$HOME/.config/quickshell.lucid-backup-$(date +%F-%H%M)" 2>/dev/null || true
        fi
      fi
      $DRY_RUN_CMD [ -e "$HOME/.config/quickshell" ] || $DRY_RUN_CMD ln -s "$HOME/.config/nixtop-shell" "$HOME/.config/quickshell" 2>/dev/null || true
      $DRY_RUN_CMD chmod +x "$HOME/.config/nixtop-shell/scripts/"* 2>/dev/null || true
    '';

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
        assertion = !(config.nixtop.lucid.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both lucid and quickshell";
      }
      {
        assertion = cfg.compositor == "sway" || cfg.compositor == "mango";
        message = "nixtop.quickshell.compositor must be mango (primary) or sway (supported)";
      }
    ];
  };
}
