{ inputs, lib, ... }: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "app.twintaillauncher.ttl"
    ];
  };
}
