{ config, lib, pkgs, inputs, ... }:
{
  # Per-user Flatpak for rose (garden) – same shape as alice's, smaller set for now.
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "dev.vencord.Vesktop"
      # add more per-user flatpaks here as needed
    ];
  };
}
