{ config, lib, pkgs, inputs, ... }:
{
  config = lib.mkIf (config.nixtop.greetd.greeter == "quickshell") {
    # Own-shell Quickshell greeter (teakettler branch ported, niri/labwc dropped)
    # Placeholder – full implementation in Phase 7 (Mango + swaybg + greeter binary)
    services.greetd.settings.default_session = lib.mkForce {
      user = "greeter";
      command = "${lib.getExe pkgs.swaybg} -i ${inputs.self}/assets/wallpaper/serial_experiments_lain_server_room.png -m fill & ${lib.getExe pkgs.hello}; wait";
    };
  };
}
