{ config, lib, pkgs, inputs, ... }:
{
  # Per-user Flatpak via nix-flatpak (D6) – this file *is* the per-user flatpak list.
  # Historically named nixpak.nix (the sandboxer nixpak is a different project);
  # we keep the filename for compatibility but this file now defines flatpaks, not sandboxes.
  # lewis has no such file → no flatpaks.
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
