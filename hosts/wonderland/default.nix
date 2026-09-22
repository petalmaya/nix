{ ... }:
{
  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

  nixtop.desktop.enable = true;
  # Extra EWM session at login; Alice's HM toggle adds the overlay.
  nixtop.ewm.enable = true;
  # SDDM is the standard greeter (see modules/core/sddm.nix).
  nixtop.greetd.greeter = "sddm";
  # Live symlinks for dev (style.css stays matugen-owned, see modules/sway/default.nix).
  nixtop.dev.liveSway = true;
  nixtop.dev.liveMako = true;
  nixtop.dev.liveWaybar = true;

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
