{ config, lib, ... }:
let
  cfg = config.nixtop.services.jellyfinProxy;
in
{
  options.nixtop.services.jellyfinProxy.enable =
    lib.mkEnableOption "LAN-only Nginx proxy for Jellyfin";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nixtop.services.jellyfin.enable;
        message = "nixtop.services.jellyfinProxy requires nixtop.services.jellyfin.enable.";
      }
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."_" = {
        default = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };

    nixtop.security.lanFirewall.tcpPorts = [ 80 ];
  };
}
