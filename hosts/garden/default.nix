{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.hostName = "garden";
  networking.extraHosts = "127.0.0.1 garden";

  nixtop.desktop.enable = true;

  # zswap via kernel params; the zswap NixOS option is not in 26.05.
  zramSwap.enable = lib.mkForce false;
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
  ];

  hardware.enableAllFirmware = true;

  # Password hash comes from sops; never commit plaintext.
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
