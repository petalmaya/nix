_: {
  networking.hostName = "wonderland";
  networking.extraHosts = "127.0.0.1 wonderland";

  nixtop = {
    desktop.enable = true;
    ewm.enable = true;
    greetd.greeter = "sddm";
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
