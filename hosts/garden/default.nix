{ config, pkgs, lib, ... }:
{
  networking.hostName = "garden";
  networking.extraHosts = "127.0.0.1 garden";

  nixtop.desktop.enable = true;

  # garden is a new laptop – use zswap instead of zram (D14)
  # zswap option not in nixos-26.05; use kernel params + disable zram
  zramSwap.enable = lib.mkForce false;
  boot.kernelParams = [ "zswap.enabled=1" "zswap.compressor=zstd" ];

  hardware.enableAllFirmware = true;

  # rose is the only user on garden (D13)
  # placeholder password – real sops secret when laptop arrives (D14)
  users.users.rose = {
    isNormalUser = true;
    # use placeholder; will be sops.hashedPasswordFile once secret provisioned
    initialPassword = "rose";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
    shell = pkgs.zsh;
  };

  # keep wifi secret logic consistent
  sops.secrets.wifi_password = {};
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
