_: {
  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

  nixtop = {
    desktop.enable = true;
    # Extra EWM session at login; Alice's HM toggle adds the overlay.
    ewm.enable = true;
    # SDDM is the standard greeter (see modules/core/sddm.nix).
    greetd.greeter = "sddm";
    # Live symlinks for dev (style.css stays matugen-owned, see modules/sway/default.nix).
    dev = {
      liveSway = true;
      liveMako = true;
      liveWaybar = true;
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  systemd.tpm2.enable = false;
}
