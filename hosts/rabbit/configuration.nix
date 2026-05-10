{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
  ];

  # Bootloader & Networking
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "rabbit"; # Corrected hostname for this host
  networking.extraHosts = "127.0.0.1 rabbit";

  # Graphics & Hardware Acceleration (Intel Broadwell)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl

      # Vulkan Drivers
      vulkan-loader
      vulkan-validation-layers
      intel-compute-runtime
    ];
  };
  boot.initrd.kernelModules = [ "i915" ];
  hardware.enableAllFirmware = true;

  system.stateVersion = "25.11";
}

