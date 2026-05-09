{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/default.nix
    ./hardware-configuration.nix
  ];

  # Bootloader & Networking
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "lookingglass";
  networking.extraHosts = "127.0.0.1 lookingglass";

  users.users.cheshire = {
    isNormalUser = true;
    initialPassword = "alice";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
  };

  system.stateVersion = "25.11";
}
