{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixtop.apps.chromium.enable =
    lib.mkEnableOption "Chromium browser configuration (replaces firefox-esr)";

  config = lib.mkIf config.nixtop.apps.chromium.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
      # Extensions – same set as firefox-esr (uBlock, Dark Reader, Bitwarden, SponsorBlock)
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      ];
      # Extra opts – keep unlocked where possible; chromium policies are locked via extraOpts.
      # Use commandLineArgs for flags that should be user-changeable.
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };

    # Make chromium the default for xdg mime where relevant (optional)
    xdg.mimeApps.defaultApplications = lib.mkDefault {
      "text/html" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/about" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "chromium-browser.desktop" ];
    };

    # For consistency with firefox-esr's pywalfox, keep a native host if user wants theming;
    # currently no pywalfox equivalent for chromium is wired – extension theming via Dark Reader.
  };
}
