# modules/home/default.nix — Home Manager module registry
#
# This file is the single entry-point imported by flake.nix as a shared
# Home Manager module.  Every sub-module is listed here so individual user
# home.nix files only need to toggle options (nixtop.<category>.<name>.enable)
# without worrying about importing the underlying files themselves.
{ ... }:

{
  imports = [
    # Fetch / system info
    ./apps/fetch

    # Browsers
    ./apps/floorp.nix
    ./apps/librewolf.nix
    ./apps/firefox-esr.nix
    ./apps/zen.nix

    # Desktop apps
    ./apps/spicetify.nix
    ./apps/gaming.nix
    ./apps/rofi.nix
    ./apps/spacemacs.nix
    ./apps/yazi.nix

    # Background services
    ./services/flatpak.nix
    ./services/mako
    ./services/mpd.nix

    # Terminal environment
    ./terminal/foot
    ./terminal/zsh
    ./terminal/tmux
    ./terminal/zellij

    # Themes
    ./themes/rosepine-dark
    ./themes/redpine
    ./themes/noctaniri
  ];
}
