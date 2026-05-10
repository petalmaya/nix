{ config, pkgs, lib, unstable-pkgs, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

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
}
