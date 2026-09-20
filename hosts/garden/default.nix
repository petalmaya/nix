{
  config,
  pkgs,
  lib,
  ...
}:
{
  networking.hostName = "garden";
  networking.extraHosts = "127.0.0.1 garden";

  nixtop.desktop.enable = true;

  # garden is a new laptop: zswap via kernel params, zram off.
  # (The zswap NixOS option is not in nixos-26.05.)
  zramSwap.enable = lib.mkForce false;
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
  ];

  hardware.enableAllFirmware = true;

  # rose is the only user on garden.
  # Placeholder password until the laptop is provisioned with a sops secret.
  users.users.rose = {
    isNormalUser = true;
    initialPassword = "rose";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
  };

  # Wi-Fi PSK from sops, written as a NetworkManager keyfile on activation.
  sops.secrets.wifi_password = { };
  system.activationScripts.wifiKeyfile = {
    deps = [ "setupSecrets" ];
    text = ''
      NM_DIR=/etc/NetworkManager/system-connections
      mkdir -p "$NM_DIR"
      WIFI_PSK=$(cat ${config.sops.secrets.wifi_password.path})
      cat > "$NM_DIR/BTRBFSTR.nmconnection" <<EOF
      [connection]
      id=BTRBFSTR
      uuid=b9f2e1d3-4a5c-4f6e-8d7b-1c2e3f4a5b6c
      type=wifi
      autoconnect=true

      [wifi]
      mode=infrastructure
      ssid=BTRBFSTR

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
      chmod 600 "$NM_DIR/BTRBFSTR.nmconnection"
    '';
  };
}
