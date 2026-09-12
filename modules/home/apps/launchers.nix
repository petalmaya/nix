{ config, lib, pkgs, ... }:

let
  cfg = config.nixtop.apps.launchers;
  packages = {
    fuzzel = pkgs.fuzzel;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.launchers = {
    enable = lib.mkEnableOption "Application launchers";
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Package names to leave out of this group.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.attrValues selectedPackages;
  };
}
