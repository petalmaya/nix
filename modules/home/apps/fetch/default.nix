{ pkgs, lib, ... }:
{
  # Fastfetch/Hyfetch
  programs.fastfetch = {
    enable = true;
  };
  
  xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;
}
