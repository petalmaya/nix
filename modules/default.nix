{
  nixosModules = [
    ./core
    ./core/apparmor.nix
    ./core/sddm.nix
    ./core/maintenance.nix
    ./browsers/chromium-policies.nix
    ./ewm
    ./shell/noctalia/greeter.nix
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
