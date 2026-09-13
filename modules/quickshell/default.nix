{ config, lib, pkgs, inputs, ... }:
let
  shell = if config ? osConfig then config.osConfig.nixtop.shell else config.nixtop.shell or "noctalia";
  shellEnabled = shell == "quickshell";
in
{
  options.nixtop.quickshell.enable = lib.mkOption {
    type = lib.types.bool;
    default = shellEnabled;
    description = "Enable Alice's own Quickshell (nixtop-shell). Deferred – follows nixtop.shell.";
  };

  config = lib.mkIf (config.nixtop.quickshell.enable && shellEnabled) {
    # Placeholder – full implementation in Phase 7.
    # When enabled, this would:
    #  - build the quickshell wrapper (package.nix)
    #  - place ~/.config/quickshell or ~/.config/nixtop-shell
    #  - handle liveQuickshell symlink
    home.packages = [ pkgs.quickshell ];

    assertions = [
      {
        assertion = !(config.nixtop.noctalia.enable or false);
        message = "nixtop.shell selects one shell – cannot enable both noctalia and quickshell";
      }
    ];

    # ensure config dir exists
    home.activation.ensureQuickshellDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/nixtop-shell"
    '';
  };
}
