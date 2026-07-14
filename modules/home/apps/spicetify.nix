# Spicetify patches the Spotify client at the binary level to inject custom
# themes and extensions.  spicetify-nix wraps this into a declarative HM module.
{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.spicetify.enable = lib.mkEnableOption "Spicetify Spotify themes and extensions";

  config = lib.mkIf config.nixtop.apps.spicetify.enable {
    programs.spicetify = let
      # legacyPackages exposes platform-specific Spicetify extensions/themes.
      # The naming follows a nixpkgs convention for packages that need to be
      # instantiated per-system rather than being pure Nix expressions.
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock       # remove ads from the Spotify client
        hidePodcasts  # hide podcast recommendations from the home screen
        shuffle       # improved shuffle that avoids repeat plays
      ];
    };
  };
}
