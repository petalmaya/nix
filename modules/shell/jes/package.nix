# JES runtime closure — qs wrapper + everything shell.qml shells out to.
# Upstream installs these system-wide (installer/JES.nix); here they are
# user packages so the jes variant works without touching the system closure.
{ pkgs }:
let
  qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtmultimedia
    pkgs.qt6.qtshadertools
    pkgs.qt6.qtwayland
    pkgs.qt6.qtimageformats
  ];
  runtimePath = pkgs.lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.jq
    pkgs.taplo
    pkgs.playerctl
    pkgs.pamixer
    pkgs.brightnessctl
    pkgs.ddcutil
    pkgs.cava
    pkgs.libnotify
    pkgs.inotify-tools
    pkgs.wl-clipboard
    pkgs.cliphist
    pkgs.grim
    pkgs.slurp
    pkgs.hyprpicker
    pkgs.foot
    pkgs.python3
    pkgs.ffmpeg
  ];
in
pkgs.symlinkJoin {
  pname = "jes-shell";
  version = "d121251";
  paths = [ pkgs.quickshell ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    makeWrapper ${pkgs.lib.getExe pkgs.quickshell} $out/bin/jes-qs \
      --set QML2_IMPORT_PATH "${qmlPath}:$HOME/.local/JES/quickshell" \
      --set QML_IMPORT_PATH "$HOME/.local/JES/quickshell:${qmlPath}" \
      --prefix PATH : "${runtimePath}"
  '';

  meta = {
    description = "Just Enough Shell wrapper (quickshell + runtime deps)";
    mainProgram = "jes-qs";
    platforms = pkgs.lib.platforms.linux;
  };
}
