{ ... }:

{
  # Imported by flake.nix for every host.
  imports = [
    ./cachix.nix
    ./mango-session.nix
    ./nagare-greeter.nix
    ./nix-ld.nix
    ./noctalia-greeter.nix
    ./plymouth.nix
    ./podman.nix
    ./teakettler-greeter.nix
    ./tor.nix
  ];
}
