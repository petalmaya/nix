{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.spicetify.enable = lib.mkEnableOption "Spicetify Spotify themes and extensions";

  config = lib.mkIf config.nixtop.apps.spicetify.enable {
    programs.spicetify = let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
      ];
    };
  };
}
