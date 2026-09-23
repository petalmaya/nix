_: {
  # Per-user Flatpaks via nix-flatpak.
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "com.usebottles.bottles"
      "com.github.tchx84.Flatseal"
      "com.adamcake.Bolt"
      "dev.vencord.Vesktop"
      "org.torproject.torbrowser-launcher"
    ];
  };
}
