{ inputs, lib, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

  networking.hostName = "pony";
  networking.extraHosts = "127.0.0.1 pony";
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  nixtop.desktop.enable = false;
  nixtop.services = {
    jellyfin.enable = true;
    jellyfinProxy.enable = true;
    netbird.enable = true;
    qbittorrent.enable = true;
    samba.enable = true;
    forgejo.enable = true;
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = true;

  zramSwap.memoryPercent = 50;
  swapDevices = lib.mkForce [ ];

  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi.firmware = {
    enable = true;
    uboot.enable = true;
  };
  boot.supportedFilesystems = [ "exfat" ];
  services.hardware.bolt.enable = lib.mkForce false;

  users.users.lewis = {
    uid = 1000;
    extraGroups = [ "media" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7LH9fOKOndanujyVwkLK1sNWh3sgWuJTOTi0CBGvp3 ink@DESKTOP-IENO7MH"
    ];
  };

  users.groups.media.gid = 983;

  fileSystems."/srv/media" = {
    device = "/dev/disk/by-uuid/5DBB-82C2";
    fsType = "exfat";
    options = [
      "uid=1000"
      "gid=983"
      "umask=0002"
      "nofail"
      "x-systemd.automount"
    ];
  };

  system.stateVersion = "26.05";
}
