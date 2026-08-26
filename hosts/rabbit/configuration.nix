{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "rabbit";
  networking.extraHosts = "127.0.0.1 rabbit";

  nixtop.desktop.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    libvdpau-va-gl
    intel-compute-runtime
  ];

  boot.initrd.kernelModules = [ "i915" ];
  hardware.enableAllFirmware = true;
}
