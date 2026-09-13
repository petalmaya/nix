{
  nixosModules = [
    ./core
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
  ];
}
