{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Placeholder session until the nixtop-shell greeter lands.
  config = lib.mkIf (config.nixtop.greetd.greeter == "quickshell") {
    services.greetd.settings.default_session = lib.mkForce {
      user = "greeter";
      command = "${lib.getExe pkgs.swaybg} -i ${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.png -m fill & ${lib.getExe pkgs.hello}; wait";
    };
  };
}
