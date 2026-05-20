{ ... }:

{
  imports = [
    ./apps/fetch
    ./apps/floorp.nix
    ./apps/gaming.nix
    ./apps/nixvim.nix
    ./apps/rofi.nix
    ./apps/spacemacs.nix
    ./apps/yazi.nix
    ./services/flatpak.nix
    ./services/mako
    ./services/mpd.nix
    ./terminal/foot
    ./terminal/tmux
    ./terminal/zsh
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
  ];
}
