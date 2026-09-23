{ config, lib, ... }:
let
  cfg = config.nixtop.wifi;
in
{
  options.nixtop.wifi = {
    ssid = lib.mkOption {
      type = lib.types.str;
      default = "BTRBFSTR";
      description = "Wi-Fi SSID to write as a NetworkManager keyfile from sops.";
    };
  };

  config = {
    sops.secrets.wifi_password = { };
    system.activationScripts.wifiKeyfile = {
      deps = [ "setupSecrets" ];
      text = ''
        NM_DIR=/etc/NetworkManager/system-connections
        mkdir -p "$NM_DIR"
        WIFI_PSK=$(cat ${config.sops.secrets.wifi_password.path})
        cat > "$NM_DIR/${cfg.ssid}.nmconnection" <<EOF
        [connection]
        id=${cfg.ssid}
        uuid=b9f2e1d3-4a5c-4f6e-8d7b-1c2e3f4a5b6c
        type=wifi
        autoconnect=true

        [wifi]
        mode=infrastructure
        ssid=${cfg.ssid}

        [wifi-security]
        auth-alg=open
        key-mgmt=wpa-psk
        psk=$WIFI_PSK

        [ipv4]
        method=auto

        [ipv6]
        addr-gen-mode=stable-privacy
        method=auto
        EOF
        chmod 600 "$NM_DIR/${cfg.ssid}.nmconnection"
      '';
    };
  };
}
