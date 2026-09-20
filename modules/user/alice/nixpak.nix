{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Per-user Flatpaks via nix-flatpak (filename is historical).
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "app.twintaillauncher.ttl"
      "com.usebottles.bottles"
      "com.github.tchx84.Flatseal"
      "io.github.Adda0.Stardrop"
      "com.adamcake.Bolt"
      "dev.vencord.Vesktop"
      "org.torproject.torbrowser-launcher"
    ];
  };
}
