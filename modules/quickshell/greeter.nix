{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  config = lib.mkIf (config.nixtop.greetd.greeter == "quickshell") {
    # Minimal greetd session until the Quickshell greeter is finished:
    # wallpaper plus a stub command so the session starts.
    services.greetd.settings.default_session = lib.mkForce {
      user = "greeter";
      command = "${lib.getExe pkgs.swaybg} -i ${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.png -m fill & ${lib.getExe pkgs.hello}; wait";
    };
  };
}
