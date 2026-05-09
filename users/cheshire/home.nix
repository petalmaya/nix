{ config, pkgs, lib, inputs, unstable-pkgs, ... }:

{
  home.username = "cheshire";
  home.homeDirectory = lib.mkForce "/home/cheshire";

  home.packages = with pkgs; [
    wget
    curl
    git
    htop
    btop
    ripgrep
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Cheshire Cat";
        email = "cheshire@lookingglass.local";
      };
    };
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
