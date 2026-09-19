# Lucid runtime closure — qs wrapper + everything the shell shells out to.
# Mirrors modules/jes/package.nix: user packages so the lucid variant works
# without touching the system closure. The shell tree itself is NOT packaged
# (it carries writable state — prefs, pins, widget layout — so activation
# copies it to ~/.config/quickshell instead; see default.nix).
# Upstream dep list: install.sh (matugen jq imagemagick, gtk portals, kitty,
# playerctl, songrec, cliphist, tesseract, cava, nautilus, ...). kitty is
# deliberately foot here (mango/foot layer); gtk/qt theming stays with our
# matugen + conf modules, not Lucid's --no-look path.
{ pkgs }:
let
  qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qt5compat # Qt5Compat.GraphicalEffects (dock, OSD, popups)
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
    pkgs.python3
    pkgs.playerctl
    pkgs.pamixer
    pkgs.brightnessctl
    pkgs.cava
    pkgs.libnotify
    pkgs.wl-clipboard
    pkgs.cliphist
    pkgs.grim
    pkgs.slurp
    pkgs.tesseract
    pkgs.songrec
    pkgs.foot
    pkgs.rsync # activation refresh of the shell tree
  ];
in
pkgs.symlinkJoin {
  pname = "lucid-shell";
  version = "1.1.0";
  paths = [ pkgs.quickshell ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    makeWrapper ${pkgs.lib.getExe pkgs.quickshell} $out/bin/lucid-qs \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --set QML_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}"
  '';

  meta = {
    description = "Lucid shell wrapper (quickshell + runtime deps)";
    mainProgram = "lucid-qs";
    platforms = pkgs.lib.platforms.linux;
  };
}
