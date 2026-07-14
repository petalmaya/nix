# Home Manager Flatpak service (managed by nix-flatpak's HM module).
# This is distinct from the system-level services.flatpak in common/default.nix:
# that one enables the Flatpak daemon; this one declares which Flatpak apps to
# install/update for the user and syncs them on every activation.
{ inputs, lib, config, ... }: {
  # Pull in the nix-flatpak Home Manager module so services.flatpak is available.
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  options.nixtop.services.flatpak.enable = lib.mkEnableOption "Flatpak service";

  config = lib.mkIf config.nixtop.services.flatpak.enable {
    services.flatpak = {
      enable = true;
      update.onActivation = true;  # keep apps up-to-date on every nixos-rebuild
      packages = [
        "app.twintaillauncher.ttl"           # Twin Tail Launcher (game launcher)
        "com.usebottles.bottles"             # Bottles (Windows app runner)
        "com.github.tchx84.Flatseal"        # Flatseal (Flatpak permissions manager)
        "io.github.Adda0.Stardrop"          # Stardrop (Stardew Valley mod manager)
        "com.adamcake.Bolt"                  # Bolt (Old School RuneScape launcher)
        "dev.vencord.Vesktop"               # Vesktop (Discord client mod)
        "org.torproject.torbrowser-launcher" # Tor Browser launcher
      ];
    };
  };
}
