{ ... }:

{
  imports = [
    ./apps/fetch
    # ./apps/floorp.nix
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
    ./wm/niri.nix
    ./wm/sway-noctalia.nix
    ./wm/sway-ribbit.nix
    ./themes/everforest
    ./themes/rosepine-dark
    ./themes/redpine
    ./themes/niripine
    ./themes/guixstyle
    ./themes/niriforest
    ./themes/noctalia.nix
    ./themes/roseniri
    ./themes/loveniri
    ./themes/pureniri
    ./themes/noctaniri
  ];
}
