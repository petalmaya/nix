{ config, lib, pkgs, ... }:
{
  networking.hostName = "garden";
  networking.extraHosts = "127.0.0.1 garden";

  nixtop.desktop.enable = true;

  # garden is a new laptop: zswap via kernel params, zram off.
  # (The zswap NixOS option is not in nixos-26.05.)
  zramSwap.enable = lib.mkForce false;
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
  ];

  hardware.enableAllFirmware = true;

  # rose is the only user on garden. Password hash comes from sops
  # (secrets/secrets.yaml: rose_password); never commit plaintext.
  sops.secrets.rose_password.neededForUsers = true;
  users.users.rose = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.rose_password.path;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
  };
}
