{ config, lib, ... }:

{
  options.nixtop.services.mpd.enable = lib.mkEnableOption "MPD music daemon";

  config = lib.mkIf config.nixtop.services.mpd.enable {
    services.mpd = {
      enable = true;
      musicDirectory = config.home.homeDirectory + "/Music";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "My PipeWire Output"
          mixer_type "software"
        }
      '';
    };

    services.mpd-mpris = {
      enable = true;
    };
  };
}
