{ config, lib, ... }:
let
  cfg = config.nixtop.lucid;
in
{
  options.nixtop.lucid.enable = lib.mkEnableOption "Lucid shell (WIP)";

  # WIP stub: lucid will be a quickshell-based shell for the mango compositor.
  # It is intentionally unconnected — nothing reads nixtop.lucid.enable yet,
  # and enabling it installs nothing. Wire it up (packages, config placement,
  # mango/sway variant, matugen template, shell-selector guard) when it starts
  # cooking. See modules/jes/default.nix for the pattern to follow.
  config = lib.mkIf cfg.enable {
    warnings = [
      "nixtop.lucid.enable does nothing yet — lucid is still cooking and unconnected."
    ];
  };
}
