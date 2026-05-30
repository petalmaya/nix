{ config, lib, pkgs, ... }:

let
  torOnionPort = 80;
  nginxInternalPort = 8080;
  webRootDirectory = "/var/www/tart4u2";
in
{
  options.nixtop.tor.enable = lib.mkEnableOption "Local Tor hidden service + nginx frontend";

  config = lib.mkIf config.nixtop.tor.enable {
    
    services.tor = {
      enable = true;
      client.enable = true;
      relay.enable = false;

      settings = {
        SafeLogging = true;
        Log = "notice stderr";
      };

      relay.onionServices."tart4u2" = {
        map = [ { port = torOnionPort; target = { addr = "127.0.0.1"; port = nginxInternalPort; }; } ];
        version = 3;
      };
    };

    services.nginx = {
      enable = true;
      serverTokens = false;
      
      virtualHosts."localhost" = {
        listen = [ { addr = "127.0.0.1"; port = nginxInternalPort; } ];
        root = webRootDirectory;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${webRootDirectory} 0755 nginx nginx"
    ];
  };
}