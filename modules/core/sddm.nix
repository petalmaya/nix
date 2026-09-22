{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nixtop.greetd;
  isSDDM = cfg.enable && cfg.greeter == "sddm";
in
{
  # SilentSDDM theme via the upstream flake module (programs.silentSDDM)
  # Only activates when nixtop.greetd.greeter == "sddm"
  config = lib.mkIf isSDDM {
    programs.silentSDDM = {
      enable = true;
      # built-in preset – see SilentSDDM configs/ folder
      # "default" is minimal; "rei" / "ken" etc are also available
      theme = lib.mkDefault "default";
      # Single background for all outputs. SilentSDDM has no per-output
      # background option – SDDM mirrors the same QML on every monitor, so
      # "login only on main" was a noctalia-greeter trait, not SDDM.
      # background-fill-mode=fill scales/crops one image to any output.
      backgrounds = {
        nixtop = ../../assets/wallpaper/misty_forest_stairs.png;
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
      # extra backgrounds / profile icons can be set per-host if desired:
      # backgrounds = { ... };
      # settings = { "LoginScreen.background" = "..."; };
    };

    # SDDM itself is enabled by programs.silentSDDM (sets
    # services.displayManager.sddm.enable, theme, GreeterEnvironment, etc.)
    # but we enforce Wayland compositor and default session here so sway
    # is the pre-selected desktop.
    services.displayManager = {
      # sway is the default desktop
      defaultSession = lib.mkDefault "sway";
      # SDDM Wayland vs X11 – force Wayland when X is not enabled, matching
      # the silentSDDM module's logic, but ensure the flag is explicit.
      sddm.wayland.enable = lib.mkDefault (!config.services.xserver.enable);
    };

    # Sway must be enabled system-wide for the session to exist.
    programs.sway = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.swayfx;
      wrapperFeatures.gtk = lib.mkDefault true;
    };

    # Keep portal + pipewire from desktop.enable – no extra work needed.
    # Ensure the greeter user exists for SDDM's internal bookkeeping (some
    # setups need a writable home)
    users.users.sddm.extraGroups = [ "video" ];
  };
}
