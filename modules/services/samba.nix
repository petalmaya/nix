{ config, lib, ... }:
let
  cfg = config.nixtop.services.samba;
  shares = {
    Movies = "/srv/media/Movies";
    Shows = "/srv/media/tv";
    Anime = "/srv/media/Anime";
    Music = "/srv/media/Music";
    Photos = "/srv/media/Photos";
    Incoming = "/srv/media/Incoming";
    Books = "/srv/media/Books";
  };
  shareSettings = lib.mapAttrs (_: path: {
    inherit path;
    "read only" = "no";
    "valid users" = "lewis";
    "force group" = "media";
    "create mask" = "0664";
    "directory mask" = "02775";
  }) shares;
in
{
  options.nixtop.services.samba.enable = lib.mkEnableOption "LAN and NetBird Samba media shares";

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = false;
      settings = shareSettings // {
        global = {
          "server role" = "standalone server";
          "bind interfaces only" = "yes";
          interfaces = "lo 10.0.0.0/24 100.64.0.0/10";
        };
      };
    };

    nixtop.security.lanFirewall.tcpPorts = [
      139
      445
    ];
    nixtop.security.lanFirewall.udpPorts = [
      137
      138
    ];
  };
}
