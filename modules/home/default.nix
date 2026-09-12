{ ... }:

{
  imports = [
    # Apps and package groups. Group modules expose an `exclude` list when a
    # profile wants most of a category without every package in it.
    ./apps/communication.nix
    ./apps/creative.nix
    ./apps/desktop.nix
    ./apps/fetch
    ./apps/gaming.nix
    ./apps/launchers.nix
    ./apps/media.nix
    ./apps/tools.nix

    # Individual apps with their own configuration.
    ./apps/browsers/floorp.nix
    ./apps/browsers/librewolf.nix
    ./apps/browsers/firefox-esr.nix
    ./apps/browsers/zen.nix
    ./apps/spicetify
    ./apps/rofi
    ./apps/yazi
    ./apps/emacs

    # User services.
    ./services/flatpak.nix
    ./services/mako
    ./services/matugen
    ./services/mpd.nix

    # Terminal programs.
    ./terminal/foot
    ./terminal/zsh
    ./terminal/tmux
    ./terminal/zellij

    # Themes and their compositor/shell configuration.
    ./themes/active.nix
    ./themes/rosepine-dark
    ./themes/redpine
    ./themes/noctaniri
    ./themes/nagare
    ./themes/manguru
    ./themes/teakettler
  ];
}
