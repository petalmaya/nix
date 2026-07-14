# MPD (Music Player Daemon) - headless music player.
# mpd-mpris bridges MPD to the MPRIS2 D-Bus interface so media key support
# and widgets like waybar's / noctalia's mpris module can control playback.
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
          # software mixer so volume works without a hardware mixer device
          mixer_type "software"
        }
      '';
    };

    # Expose MPD state over MPRIS2 D-Bus so waybar/media keys work.
    services.mpd-mpris = {
      enable = true;
    };
  };
}
