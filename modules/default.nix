{
  nixosModules = [
    ./core
    ./core/apparmor.nix
    ./core/sddm.nix
    ./core/maintenance.nix
    ./shell/noctalia/greeter.nix
    ./shell/quickshell/greeter.nix
  ];

  homeModules = [
    ./core/zsh.nix
    ./core/tmux.nix
    ./browsers
    ./conf
    ./emacs
    ./mango
    ./matugen
    ./sway
    ./shell
  ];
}
