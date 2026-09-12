{ config, lib, pkgs, unstable-pkgs, ... }:

let
  cfg = config.nixtop.apps.desktop;
  packages = {
    mousepad = pkgs.mousepad;
    nautilus = pkgs.nautilus;
    mpvpaper = pkgs.mpvpaper;
    swaybg = pkgs.swaybg;
    libnotify = pkgs.libnotify;
    grim = pkgs.grim;
    slurp = pkgs.slurp;
    swaylock = pkgs.swaylock;
    brightnessctl = pkgs.brightnessctl;
    "wl-clipboard" = pkgs.wl-clipboard;
    playerctl = pkgs.playerctl;
    gvfs = pkgs.gvfs;
    pulseaudio = pkgs.pulseaudio;
    "adw-gtk3" = pkgs.adw-gtk3;
    "capitaine-cursors" = pkgs.capitaine-cursors;
    "polkit_gnome" = pkgs.polkit_gnome;
  };

  selectedPackages = lib.filterAttrs
    (name: _: !builtins.elem name cfg.exclude)
    packages;
in
{
  options.nixtop.apps.desktop = {
    enable = lib.mkEnableOption "Desktop utilities and appearance packages";
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
