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
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      ];
      # Allows fallback to x11
      commandLineArgs = [
        "--ozone-platform-hint=auto"
      ];
    };

    # Hardening policies live in ./chromium-policies.nix (NixOS side; HM's
    # programs.chromium has no policy options).

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
