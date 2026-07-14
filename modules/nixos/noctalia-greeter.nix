{ config, lib, pkgs, inputs, ... }:

{
  options.nixtop.noctalia-greeter.enable = lib.mkEnableOption "Noctalia Greeter using greetd";

  config = lib.mkIf config.nixtop.noctalia-greeter.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "capitaine-cursors";
          size = 24;
          path = "${pkgs.capitaine-cursors}/share/icons";
        };
      };
    };

    # Let it see niri
    services.displayManager.sessionPackages = [
      inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable
    ];
  };
}
