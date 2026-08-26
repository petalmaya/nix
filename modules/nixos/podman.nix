{ pkgs, ... }: {

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;

    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui
    dive
    skopeo
  ];

  users.users.alice.extraGroups = [ "podman" ];
}
