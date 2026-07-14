# Gaming tools and launchers.
{ pkgs, lib, config, unstable-pkgs, ... }:

{
  options.nixtop.apps.gaming.enable = lib.mkEnableOption "Gaming applications";

  config = lib.mkIf config.nixtop.apps.gaming.enable {
    home.packages = with pkgs; [
      wine            # Windows compatibility layer / Litterly never works though
      renpy           # visual novel engine
      obs-studio      # screen recording / streaming
      prismlauncher   # multi-instance Minecraft launcher
      openttd         # open-source Transport Tycoon / Addictive
      openrct2        # open-source RollerCoaster Tycoon 2
      steam-run       # run arbitrary binaries in the Steam FHS environment
      pokemmo-installer # Pokemon MMO
    ];
  };
}
