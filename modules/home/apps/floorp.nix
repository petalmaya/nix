{ pkgs, lib, config, inputs, ... }:

{
  options.nixtop.apps.floorp.enable = lib.mkEnableOption "Floorp browser configuration";

  config = lib.mkIf config.nixtop.apps.floorp.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.floorp-bin;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
      profiles.${config.home.username} = {
        isDefault = true;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          ublock-origin
          darkreader
          bitwarden
          sponsorblock
        ];
        settings = {
          "extensions.autoDisableScopes" = 0;
        };
      };
    };

    # Symlink Floorp config to Firefox config so it picks up the managed profile
    home.file.".floorp".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/mozilla/firefox";
  };
}
