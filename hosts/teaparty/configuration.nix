{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../common/default.nix
    ../common/home-wifi.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  # Bootloader & Networking
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "teaparty";
  networking.extraHosts = "127.0.0.1 teaparty";

  # Graphics and XFCE setup
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  # Services for hosting files & remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Allow password for easy initial login
    };
  };

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

  system.stateVersion = "25.11";
}
