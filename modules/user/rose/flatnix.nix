_: {
  # Per-user Flatpaks via nix-flatpak.
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "dev.vencord.Vesktop"
    ];
  };
}
