{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "lookingglass";
  networking.extraHosts = "127.0.0.1 lookingglass";

  # Note: nixtop.desktop.enable is NOT set to true here since lookingglass is a headless server host.
  # nixtop.tor.enable = false;

  sops.secrets.cheshire_password.neededForUsers = true;
  users.users.cheshire = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.cheshire_password.path;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
  };
}
