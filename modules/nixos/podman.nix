# modules/nixos/podman.nix
{ pkgs, ... }: {

  # Enable Podman with Docker compatibility
  virtualisation.podman = {
    enable = true;

    # Create a `docker` alias so Docker-targeting tools work transparently
    dockerCompat = true;

    # Allow containers to resolve each other by name on the default network
    defaultNetwork.settings.dns_enabled = true;

    # Auto-update policy for containers managed via quadlets/systemd
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };
  };

  # Useful CLI companions
  environment.systemPackages = with pkgs; [
    podman-compose   # docker-compose-compatible workflow
    podman-tui       # interactive TUI for container management
    dive             # explore image layers
    skopeo           # inspect / copy OCI images without pulling
  ];

  # Add alice to the "podman" group (created automatically) — also ensures
  # the user can manage the system Podman socket if ever needed
  users.users.alice.extraGroups = [ "podman" ];
}
