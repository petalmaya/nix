{
  config,
  lib,
  unstable-pkgs,
  ...
}:
let
  cfg = config.nixtop.services.netbird;
  unstable = unstable-pkgs;
in
{
  options.nixtop.services.netbird.enable = lib.mkEnableOption "NetBird mesh client";

  config = lib.mkIf cfg.enable {
    services.netbird = {
      enable = true;
      package = unstable.netbird;
      clients.default.openFirewall = false;
    };
  };
}
