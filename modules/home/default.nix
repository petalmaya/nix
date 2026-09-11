{ ... }:

{
  imports = [
    ./apps/fetch
    
    # Browsers
    ./apps/browsers/floorp.nix
    ./apps/browsers/librewolf.nix
    ./apps/browsers/firefox-esr.nix
    ./apps/browsers/zen.nix

    ./apps/spicetify
    ./apps/gaming.nix
    ./apps/rofi
    ./apps/yazi
    ./apps/emacs

    ./services/flatpak.nix
    ./services/mako
    ./services/matugen
    ./services/mpd.nix

    ./terminal/foot
    ./terminal/zsh
    ./terminal/tmux
    ./terminal/zellij

    ./themes/active.nix
    ./themes/rosepine-dark
    ./themes/redpine
    ./themes/noctaniri
    ./themes/nagare
    ./themes/manguru
    ./themes/teakettler
  ];
}
