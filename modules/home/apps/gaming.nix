{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bottles
    wine
    renpy
    obs-studio
    prismlauncher
    openttd
    openrct2
    bolt-launcher
    balatro
    unstable-pkgs.vesktop
  ];
}
