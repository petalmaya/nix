{ config, lib, pkgs, unstable-pkgs, ... }:

let
  cfg = config.nixtop.apps.creative;
  packages = {
    krita = pkgs.krita;
    gimp = pkgs.gimp;
    "blockbench" = pkgs.blockbench;
    "antigravity-ide" = unstable-pkgs.antigravity-ide;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.creative = {
    enable = lib.mkEnableOption "Creative applications";
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
