# Noctalia Greeter is a custom login/display manager built on top of greetd.
# It needs to know the available Wayland compositor sessions so the session
# picker can display them — hence registering niri as a session package.
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
          # Absolute path to the cursor theme inside the Nix store so the
          # greeter (which runs before the user session) can find the icons.
          path = "${pkgs.capitaine-cursors}/share/icons";
        };
      };
    };

    # Register niri as a valid session so greetd lists it.
    services.displayManager.sessionPackages = [
      inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable
    ];
  };
}
