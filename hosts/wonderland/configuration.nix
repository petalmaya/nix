{ config, pkgs, lib, unstable-pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

  # Enable desktop environment and graphical configuration
  nixtop.desktop.enable = true;

  # Enable tor/nginx service
  nixtop.tor.enable = true;

  boot.initrd.kernelModules = [ "i915" ];

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      intel-compute-runtime
  ];

  # Locale / Encoding
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
    ];
  };

  hardware.enableAllFirmware = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Fix TPM0 systemd boot timeout
  systemd.tpm2.enable = false;
}
