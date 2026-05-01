{ pkgs, lib, config, inputs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.floorp-bin;
    profiles.alice = {
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
  home.file.".floorp".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.mozilla/firefox";
}
