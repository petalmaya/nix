{
  nixosModules = [
    ./core
    ./core/apparmor.nix
    ./core/sddm.nix
    ./core/maintenance.nix
    ./noctalia/greeter.nix
    ./quickshell/greeter.nix
  ];

  homeModules = [
    ./core/zsh.nix
    ./core/tmux.nix
    ./browsers
    ./conf
    ./emacs
    ./mango
    ./matugen
    ./noctalia
    ./quickshell
    ./jes
    ./lucid
    ./sway
    ./shell
  ];
}
