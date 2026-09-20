{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixtop.apps.chromium.enable = lib.mkEnableOption "Chromium browser configuration";

  config = lib.mkIf config.nixtop.apps.chromium.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
      # uBlock Origin, Dark Reader, Bitwarden, SponsorBlock
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      ];
      # Chromium policies set via extraOpts are locked; use commandLineArgs
      # for flags that should stay user-changeable.
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };

    # Make chromium the default handler for web MIME types.
    xdg.mimeApps.defaultApplications = lib.mkDefault {
      "text/html" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/about" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "chromium-browser.desktop" ];
    };
  };
}
