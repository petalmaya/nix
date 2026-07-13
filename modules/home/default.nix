{ ... }:

{
  imports = [
    ./apps/fetch
    ./apps/floorp.nix
    ./apps/librewolf.nix
    ./apps/firefox-esr.nix
    ./apps/spicetify.nix
    ./apps/zen.nix
    ./apps/gaming.nix
    ./apps/rofi.nix
    ./apps/spacemacs.nix
    ./apps/yazi.nix
    ./services/flatpak.nix
    ./services/mako
    ./services/mpd.nix
    ./terminal/foot
    ./terminal/zsh
    ./terminal/tmux
    ./terminal/zellij
    ./themes/rosepine-dark
    ./themes/redpine
    ./themes/noctaniri
  ];
}
