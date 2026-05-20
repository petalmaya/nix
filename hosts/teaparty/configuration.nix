{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "teaparty";
  networking.extraHosts = "127.0.0.1 teaparty";

  # Enable desktop environment and graphical configuration
  nixtop.desktop.enable = true;

  # Graphics and XFCE setup
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  # User definitions for this host specifically
  sops.secrets.hatter_password.neededForUsers = true;
  users.users.hatter = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.hatter_password.path;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };

  environment.systemPackages = with pkgs; [
    sshfs
  ];
}
