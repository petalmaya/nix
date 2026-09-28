{
  nixosModules = [
    ./core
    ./core/apparmor.nix
    ./core/hardening.nix
    ./core/sddm.nix
    ./core/maintenance.nix
    ./core/lan-firewall.nix
    ./browsers/chromium-policies.nix
    ./services/jellyfin.nix
    ./services/jellyfin-proxy.nix
    ./services/netbird.nix
    ./services/qbittorrent.nix
    ./services/samba.nix
    ./services/forgejo.nix
    ./ewm
    ./shell/quickshell/greeter.nix
  ];

  homeModules = [
    ./core/zsh.nix
    ./core/tmux.nix
    ./browsers
    ./conf
    ./emacs
    ./ewm/home.nix
    ./mango
    ./matugen
    ./sway
    ./shell
  ];
}
