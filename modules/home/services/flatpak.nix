{ inputs, lib, config, ... }: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  options.nixtop.services.flatpak.enable = lib.mkEnableOption "Flatpak service";

  config = lib.mkIf config.nixtop.services.flatpak.enable {
    services.flatpak = {
      enable = true;
      update.onActivation = true;
      packages = [
        "app.twintaillauncher.ttl"
        "com.usebottles.bottles"
        "com.github.tchx84.Flatseal"
        "io.github.Adda0.Stardrop"
        "com.adamcake.Bolt"
        "com.valvesoftware.Steam"
        "dev.vencord.Vesktop"
      ];
    };
  };
}
