{ config, lib, ... }:
let
  cfg = config.nixtop.services.jellyfin;
in
{
  options.nixtop.services.jellyfin.enable = lib.mkEnableOption "Jellyfin media server";

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      group = "media";
      openFirewall = false;
    };

    systemd.services.jellyfin.serviceConfig.ReadOnlyPaths = [ "/srv/media" ];
  };
}
