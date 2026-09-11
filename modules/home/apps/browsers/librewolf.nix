{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.librewolf.enable = lib.mkEnableOption "LibreWolf browser configuration";

  config = lib.mkIf config.nixtop.apps.librewolf.enable {
    programs.librewolf = {
      enable = true;
      profiles.${config.home.username} = {
        isDefault = true;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          pywalfox
          darkreader
          bitwarden
          sponsorblock
        ];
        settings = {
          "extensions.autoDisableScopes" = 0;
        };
      };
    };
  };
}

