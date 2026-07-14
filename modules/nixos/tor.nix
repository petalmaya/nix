# Sets up a Tor hidden service backed by a local nginx instance.
# The onion service forwards external port 80 to nginx on 127.0.0.1:8080,
# serving static files from /var/www/tart4u2.
{ config, lib, pkgs, ... }:

let
  torOnionPort = 80;          # port Tor advertises on the .onion address
  nginxInternalPort = 8080;   # local nginx listener (never exposed publicly)
  webRootDirectory = "/var/www/tart4u2"; # static site root
in
{
  options.nixtop.tor.enable = lib.mkEnableOption "Local Tor hidden service + nginx frontend";

  config = lib.mkIf config.nixtop.tor.enable {
    
    services.tor = {
      enable = true;
      client.enable = true;   # run as a client so apps can route through SOCKS
      relay.enable = false;   # not a relay — stays private

      settings = {
        SafeLogging = true;   # scrub potentially identifying info from logs
        Log = "notice stderr";
      };

      # Map the onion port to nginx so Tor traffic reaches our static site.
      relay.onionServices."tart4u2" = {
        map = [ { port = torOnionPort; target = { addr = "127.0.0.1"; port = nginxInternalPort; }; } ];
        version = 3;  # v3 onion addresses (56-char, Ed25519-based)
      };
    };

    services.nginx = {
      enable = true;
      serverTokens = false;  # don't leak nginx version in response headers

      # Only listen on loopback so it's unreachable except through Tor.
      virtualHosts."localhost" = {
        listen = [ { addr = "127.0.0.1"; port = nginxInternalPort; } ];
        root = webRootDirectory;
      };
    };

    # Create the web root directory owned by nginx if it doesn't exist yet.
    systemd.tmpfiles.rules = [
      "d ${webRootDirectory} 0755 nginx nginx"
    ];
  };
}