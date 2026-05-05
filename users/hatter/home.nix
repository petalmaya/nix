{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  home.username = "hatter";
  home.homeDirectory = lib.mkForce "/home/hatter";

  home.packages = with pkgs; [
    wget
    curl
    git
    htop
    btop
    ripgrep
    # Basic tools for hosting/XFCE
    xfce.thunar
    xfce.xfce4-terminal
  ];

  # Basic Git setup
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Mad Hatter";
        email = "hatter@wonderland.local";
      };
    };
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
