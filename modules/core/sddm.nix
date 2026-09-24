{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixtop.greetd;
  isSDDM = cfg.enable && cfg.greeter == "sddm";
in
{
  # SilentSDDM theme; only activates for the sddm greeter.
  config = lib.mkIf isSDDM {
    programs.silentSDDM = {
      enable = true;
      theme = lib.mkDefault "default";
      # SDDM mirrors one image on every monitor.
      backgrounds = {
        nixtop = ../../assets/greeter/misty_forest_stairs.png;
      };
      settings = {
        General = {
          background-fill-mode = "fill";
        };
        LoginScreen = {
          background = "misty_forest_stairs.png";
          scale = 1.0;
        };
      };
    };

    # Sway must be enabled system-wide for the session to exist.
    services.displayManager = {
      defaultSession = lib.mkDefault "sway";
      sddm.wayland.enable = lib.mkDefault (!config.services.xserver.enable);
    };

    programs.sway = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.swayfx;
      wrapperFeatures.gtk = lib.mkDefault true;
    };

    users.users.sddm.extraGroups = [ "video" ];
  };
}
