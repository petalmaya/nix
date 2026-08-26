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

  nixtop.desktop.enable = true;
  nixtop.tor.enable = false;

  boot.initrd.kernelModules = [ "i915" ];

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      intel-compute-runtime
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
    ];
  };

  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  # old laptop, tpm0 hangs the boot for ages otherwise
  systemd.tpm2.enable = false;
}
