{ config, lib, ... }:
let
  cfg = config.nixtop.security.hardening;
in
{
  options.nixtop.security.hardening = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Everyday hardening baseline: firewall, SSH, sudo, sysctl, /tmp, DNS, Nix pins.";
    };
    sshLanOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Close sshd on all interfaces and re-allow port 22 from RFC1918/ULA/link-local only.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        networking = {
          firewall = {
            enable = true;
            allowPing = false;
            logRefusedConnections = true;
          };
          networkmanager.wifi = {
            macAddress = "random";
            scanRandMacAddress = true;
          };
        };

        services = {
          openssh = {
            openFirewall = false;
            settings = {
              MaxAuthTries = 3;
              LoginGraceTime = "30s";
              ClientAliveInterval = 300;
              ClientAliveCountMax = 2;
              MaxSessions = 2;
              X11Forwarding = false;
              AllowTcpForwarding = "local";
              PermitEmptyPasswords = false;
              KexAlgorithms = [
                "curve25519-sha256"
                "curve25519-sha256@libssh.org"
              ];
              Ciphers = [
                "chacha20-poly1305@openssh.com"
                "aes256-gcm@openssh.com"
                "aes128-gcm@openssh.com"
              ];
              Macs = [
                "hmac-sha2-512-etm@openssh.com"
                "hmac-sha2-256-etm@openssh.com"
              ];
            };
          };
          hardware.bolt.enable = true;
          resolved = {
            enable = true;
            settings.Resolve.DNSOverTLS = "opportunistic";
          };
        };

        security = {
          sudo = {
            execWheelOnly = true;
            wheelNeedsPassword = true;
            extraConfig = ''
              Defaults lecture
              Defaults timestamp_timeout=15
            '';
          };
          pam.services.sudo.logFailures = true;
          pam.services.login.logFailures = true;
        };

        environment.etc."security/faillock.conf".text = ''
          dir = /var/run/faillock
          deny = 5
          fail_interval = 900
          unlock_time = 300
          silent
        '';

        boot = {
          kernel.sysctl = {
            "kernel.dmesg_restrict" = 1;
            "kernel.kptr_restrict" = 2;
            "kernel.unprivileged_bpf_disabled" = 2;
            "kernel.yama.ptrace_scope" = 1;
            "kernel.perf_event_paranoid" = 2;
            "net.ipv4.conf.all.rp_filter" = 1;
            "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
            "net.ipv4.conf.all.accept_redirects" = 0;
            "net.ipv4.conf.all.send_redirects" = 0;
          };
          tmp = {
            useTmpfs = true;
            tmpfsSize = "25%";
            cleanOnBoot = true;
          };
          blacklistedKernelModules = [
            "dccp"
            "sctp"
            "rds"
            "tipc"
            "firewire-core"
            "firewire-ohci"
          ];
        };

        systemd.coredump.settings.Coredump.Storage = "none";

        nix.settings = {
          sandbox = true;
          "require-sigs" = true;
        };
      }

      (lib.mkIf cfg.sshLanOnly {
        networking.firewall.extraCommands = ''
          iptables -A nixos-fw -p tcp --source 10.0.0.0/8 --dport 22 -j nixos-fw-accept || true
          iptables -A nixos-fw -p tcp --source 172.16.0.0/12 --dport 22 -j nixos-fw-accept || true
          iptables -A nixos-fw -p tcp --source 192.168.0.0/16 --dport 22 -j nixos-fw-accept || true
          ip6tables -A nixos-fw -p tcp --source fe80::/10 --dport 22 -j nixos-fw-accept || true
          ip6tables -A nixos-fw -p tcp --source fc00::/7 --dport 22 -j nixos-fw-accept || true
        '';
      })
    ]
  );
}
