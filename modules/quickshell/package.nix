# Builds nixtop-shell (+ greeter) from ./shell, plus the Go sway IPC daemon.
#
# nixtop-shell wraps bare `qs` (config resolves via ~/.config/nixtop-shell,
# see default.nix). The greeter bakes a store copy of the config instead,
# since it runs as its own user with no repo checkout to symlink into.
{ pkgs, quickshellInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qs = quickshellInput.packages.${system}.default;

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

  # Go IPC daemon — sway's `swaymsg` per-frame is ~15ms & forks; Go daemon
  # holds one IPC socket, writes a cache file, QML just FileViews it (caelestia/dank pattern)
  swayIpc = pkgs.buildGoModule {
    pname = "nixtop-sway-ipc";
    version = "0.1.0";
    src = ./ipc;
    vendorHash = null; # no deps — stdlib only
    subPackages = [ "." ];
    ldflags = [
      "-s"
      "-w"
    ];
    # buildGoModule names the binary after the directory (`ipc`), but we want `nixtop-sway-ipc`
    postInstall = ''
      
            if [ -f $out/bin/ipc ]; then mv $out/bin/ipc $out/bin/nixtop-sway-ipc; fi
            if [ -f $out/bin/daemon ]; then mv $out/bin/daemon $out/bin/nixtop-sway-ipc; fi
            # also provide `ipc` as alias for debugging
            ln -s $out/bin/nixtop-sway-ipc $out/bin/ipc 2>/dev/null || true
    '';
  };
in
pkgs.symlinkJoin {
  pname = "nixtop-shell";
  version = qs.version or "unstable";
  paths = [
    qs
    swayIpc
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    
        makeWrapper ${pkgs.lib.getExe qs} $out/bin/nixtop-shell \
          --set FONTCONFIG_FILE "${fontconfig}" \
          --set QML2_IMPORT_PATH "${qmlPath}" \
          --prefix PATH : "${runtimePath}:${swayIpc}/bin" \
          --set NIXTOP_SHELL_IPC "${swayIpc}/bin/nixtop-sway-ipc"
    
        makeWrapper ${pkgs.lib.getExe qs} $out/bin/nixtop-shell-greeter \
          --set FONTCONFIG_FILE "${fontconfig}" \
          --set QML2_IMPORT_PATH "${qmlPath}" \
          --prefix PATH : "${runtimePath}:${swayIpc}/bin" \
          --set NIXTOP_SHELL_IPC "${swayIpc}/bin/nixtop-sway-ipc" \
          --add-flags '-p ${greeterConfigSrc}'
    
        # also expose the daemon directly for systemd/user or `qs ipc` debugging
        ln -s ${swayIpc}/bin/nixtop-sway-ipc $out/bin/nixtop-sway-ipc || true
  '';

  meta = {
    description = "nixtop-shell - quickshell config for mango (primary) and sway (Go IPC daemon)";
    mainProgram = "nixtop-shell";
    platforms = pkgs.lib.platforms.linux;
  };
}
