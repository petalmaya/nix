{ config, lib, ... }:
let
  cfg = config.nixtop.services.qbittorrent;
in
{
  options.nixtop.services.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent headless service";
    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "qBittorrent Web UI port.";
    };
    torrentPort = lib.mkOption {
      type = lib.types.port;
      default = 51413;
      description = "qBittorrent peer port.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.qbittorrent = {
      enable = true;
      group = "media";
      openFirewall = false;
      webuiPort = cfg.webuiPort;
      torrentingPort = cfg.torrentPort;
    };

    nixtop.security.lanFirewall.tcpPorts = [
      cfg.webuiPort
      cfg.torrentPort
    ];
    nixtop.security.lanFirewall.udpPorts = [ cfg.torrentPort ];
  };
}
