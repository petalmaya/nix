{ config, lib, ... }:
let
  cfg = config.nixtop.services.forgejo;
in
{
  options.nixtop.services.forgejo.enable = lib.mkEnableOption "LAN-only Forgejo instance";

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      settings = {
        server = {
          DOMAIN = "10.0.0.79";
          HTTP_ADDR = "0.0.0.0";
          HTTP_PORT = 3000;
          ROOT_URL = "http://10.0.0.79:3000/";
        };
        service.DISABLE_REGISTRATION = true;
      };
    };

    nixtop.security.lanFirewall.tcpPorts = [ 3000 ];
  };
}
