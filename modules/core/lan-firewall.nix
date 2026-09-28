{ config, lib, ... }:
let
  cfg = config.nixtop.security.lanFirewall;
  mkRules =
    command: protocol: networks: ports:
    if ports == [ ] then
      ""
    else
      let
        portList = lib.concatMapStringsSep "," toString ports;
      in
      lib.concatMapStringsSep "\n" (
        network:
        "${command} -A nixos-fw -p ${protocol} --source ${network} -m multiport --dports ${portList} -j nixos-fw-accept"
      ) networks;
in
{
  options.nixtop.security.lanFirewall = {
    enable = lib.mkEnableOption "LAN-only inbound service ports" // {
      default = true;
    };
    ipv4Networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "10.0.0.0/24"
        "100.64.0.0/10"
      ];
      description = "IPv4 LAN and private mesh networks allowed to reach registered service ports.";
    };
    ipv6Networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "fc00::/7" ];
      description = "IPv6 private networks allowed to reach registered service ports.";
    };
    tcpPorts = lib.mkOption {
      type = lib.types.listOf (lib.types.ints.between 1 65535);
      default = [ ];
      description = "TCP service ports accepted only from the configured private networks.";
    };
    udpPorts = lib.mkOption {
      type = lib.types.listOf (lib.types.ints.between 1 65535);
      default = [ ];
      description = "UDP service ports accepted only from the configured private networks.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = lib.concatStringsSep "\n" [
      (mkRules "iptables" "tcp" cfg.ipv4Networks cfg.tcpPorts)
      (mkRules "iptables" "udp" cfg.ipv4Networks cfg.udpPorts)
      (mkRules "ip6tables" "tcp" cfg.ipv6Networks cfg.tcpPorts)
      (mkRules "ip6tables" "udp" cfg.ipv6Networks cfg.udpPorts)
    ];
  };
}
