# wayland-sessions/mango.desktop, so kurukurubar-greeter's session
# scanner (scripts/session.sh) picks mango up - mirrors what niri's own
# package already ships, mango doesn't bundle one yet
{ config, lib, pkgs, unstable-pkgs, ... }:
let
  mangoSession = pkgs.writeTextDir "share/wayland-sessions/mango.desktop" ''
    [Desktop Entry]
    Name=Mango
    Comment=MangoWC, a dwm-like Wayland compositor
    Exec=${lib.getExe unstable-pkgs.mango}
    Type=Application
  '';
in {
  options.nixtop.mango-session.enable = lib.mkEnableOption "Register mango as a selectable wayland-session";

  config = lib.mkIf config.nixtop.mango-session.enable {
    services.displayManager.sessionPackages = [ mangoSession ];
  };
}
