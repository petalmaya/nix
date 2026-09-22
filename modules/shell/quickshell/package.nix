# Builds nixtop-shell (+ greeter) from ./shell, plus the Go sway IPC daemon.
#
# nixtop-shell wraps bare `qs` (config resolves via ~/.config/nixtop-shell,
# see default.nix). The greeter bakes a store copy of the config instead,
# since it runs as its own user with no repo checkout to symlink into.
{ pkgs }:
let
  qs = pkgs.quickshell;

  configSrc = pkgs.lib.fileset.toSource {
    root = ./shell;
    fileset = ./shell;
  };

  # greeter.qml swapped in as shell.qml
  greeterConfigSrc = pkgs.runCommand "nixtop-shell-greeter-config" { } ''

    cp -r ${configSrc} $out
    chmod -R u+w $out
    rm -f $out/shell.qml
    mv $out/greeter.qml $out/shell.qml
  '';

  fontconfig = pkgs.makeFontsConf {
    fontDirectories = [
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
      pkgs.rubik
    ];
  };

  qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.kdePackages.qtmultimedia
    pkgs.qt6.qt5compat
  ];

  # bash/coreutils/findutils/gawk are for scripts/session.sh, which the
  # greeter runs under greetd's minimal env (no user PATH)
  runtimePath = pkgs.lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.rembg
    pkgs.brightnessctl
    pkgs.power-profiles-daemon
  ];

  # Go IPC daemons — one source, two compositor modes (same binary, two names).
  # Sway's `swaymsg` per-frame is ~15ms & forks; mango's `mmsg watch` line is
  # parsed in QML per event. The daemon holds the socket/subprocess, writes a
  # cache file, QML just FileViews it (caelestia/dank pattern):
  # sway mode -> $XDG_CACHE_HOME/nixtop-shell/sway.json (Data/Sway.qml),
  # mango mode -> .../mango.json (Data/MangoWC.qml, --mango / auto-detect).
  ipcDaemons = pkgs.buildGoModule {
    pname = "nixtop-ipc-daemons";
    version = "0.2.0";
    src = ./ipc;
    vendorHash = null; # no deps — stdlib only
    subPackages = [ "." ];
    ldflags = [
      "-s"
      "-w"
    ];
    # Binary name follows go.mod (`nixtop-shell-ipc`), not the directory —
    # install real files (not symlinks) under both launch names QML looks up:
    # `nixtop-sway-ipc` (Data/Sway.qml) and `nixtop-mango-ipc` (Data/MangoWC.qml).
    # Copies, never symlinks, so noBrokenSymlinks cannot fire.
    # The debug `ipc` alias is relative, created only when its target exists.
    postInstall = ''

      base=""
      if [ -f $out/bin/nixtop-shell-ipc ]; then
        base="$out/bin/nixtop-shell-ipc"
      elif [ -f $out/bin/ipc ]; then
        base="$out/bin/ipc"
      elif [ -f $out/bin/daemon ]; then
        base="$out/bin/daemon"
      fi
      if [ -n "$base" ]; then
        cp "$base" $out/bin/nixtop-sway-ipc
        cp "$base" $out/bin/nixtop-mango-ipc
        if [ "$base" != "$out/bin/nixtop-shell-ipc" ]; then
          cp "$base" $out/bin/nixtop-shell-ipc
        fi
        rm -f $out/bin/ipc
        ln -s nixtop-sway-ipc $out/bin/ipc
      fi
    '';
  };
in
pkgs.symlinkJoin {
  pname = "nixtop-shell";
  version = qs.version or "unstable";
  paths = [
    qs
    ipcDaemons
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''

    makeWrapper ${pkgs.lib.getExe qs} $out/bin/nixtop-shell \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}:${ipcDaemons}/bin" \
      --set NIXTOP_SHELL_IPC "${ipcDaemons}/bin/nixtop-sway-ipc" \
      --set NIXTOP_SHELL_MANGO_IPC "${ipcDaemons}/bin/nixtop-mango-ipc"

    makeWrapper ${pkgs.lib.getExe qs} $out/bin/nixtop-shell-greeter \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}:${ipcDaemons}/bin" \
      --set NIXTOP_SHELL_IPC "${ipcDaemons}/bin/nixtop-sway-ipc" \
      --set NIXTOP_SHELL_MANGO_IPC "${ipcDaemons}/bin/nixtop-mango-ipc" \
      --add-flags '-p ${greeterConfigSrc}'

    # also expose the daemons directly for systemd/user or `qs ipc` debugging
    # (symlinkJoin already merges ipcDaemons' bin, so only link when missing)
    if [ ! -e $out/bin/nixtop-sway-ipc ] && [ -e ${ipcDaemons}/bin/nixtop-sway-ipc ]; then
      ln -s ${ipcDaemons}/bin/nixtop-sway-ipc $out/bin/nixtop-sway-ipc
    fi
    if [ ! -e $out/bin/nixtop-mango-ipc ] && [ -e ${ipcDaemons}/bin/nixtop-mango-ipc ]; then
      ln -s ${ipcDaemons}/bin/nixtop-mango-ipc $out/bin/nixtop-mango-ipc
    fi
  '';

  meta = {
    description = "nixtop-shell - quickshell config for mango and sway (Go IPC daemons)";
    mainProgram = "nixtop-shell";
    platforms = pkgs.lib.platforms.linux;
  };
}
