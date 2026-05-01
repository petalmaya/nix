{ ... }:

{
  services.mpd = {
    enable = true;
    musicDirectory = "/home/alice/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My PipeWire Output"
        mixer_type "software"
      }
    '';
  };
}
