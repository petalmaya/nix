{ config, pkgs, lib, ... }:
{
  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

  nixtop.desktop.enable = true;

  boot.initrd.kernelModules = [ "i915" ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
    intel-compute-runtime
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  systemd.tpm2.enable = false;

  # wifi secret activation (moved from hosts/common/home-wifi.nix – keep in core or host)
  # imported via core/wifi.nix if exists, but we keep activation here for now:
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
