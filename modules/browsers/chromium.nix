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
      # Full uBlock Origin is MV2-only and dead on Chromium 139+; uBOL is
      # gorhill's official MV3 build. The rest are MV3-compatible.
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      ];
      # Wrapper flag only, no Chromium rebuild. hint=auto picks Wayland
      # under sway/mango and still falls back to X11/XWayland.
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
