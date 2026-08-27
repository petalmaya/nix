{ ... }:

{
  imports = [
    ./apps/fetch

    ./apps/floorp.nix
    ./apps/librewolf.nix
    ./apps/firefox-esr.nix
    ./apps/zen.nix

    ./apps/spicetify.nix
    ./apps/gaming.nix
    ./apps/rofi
    ./apps/yazi.nix
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
    ./themes/kurukuru
    ./themes/manguru
  ];
}
