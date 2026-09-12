{ config, lib, pkgs, unstable-pkgs, ... }:

let
  cfg = config.nixtop.apps.communication;
  packages = {
    links2 = pkgs.links2;
    "tutanota-desktop" = unstable-pkgs.tutanota-desktop;
    "transmission_4-gtk" = pkgs.transmission_4-gtk;
    "nicotine-plus" = pkgs.nicotine-plus;
    "cinny-desktop" = pkgs.cinny-desktop;
    weechat = pkgs.weechat;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.communication = {
    enable = lib.mkEnableOption "Communication and file-sharing applications";
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
