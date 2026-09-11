# builds teakettler's shell (+ greeter) from the vendored ./quickshell
# config. forked from nagare/package.nix so the two themes evolve
# independently - nothing here reads ../nagare.
#
# `teakettler` (the shell) is a thin wrapper around bare `qs`, which
# resolves ~/.config/quickshell (the out-of-store symlink set up in
# default.nix). the greeter gets a real store-built copy instead since it
# runs as its own user with no checkout to symlink into.
#
# The binaries are teakettler / teakettler-greeter: nothing in this tree
# is called `nagarebar` any more. The greeter session is set up by
# modules/nixos/teakettler-greeter.nix, which calls `teakettler-greeter`.
{ pkgs, quickshellInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qs = quickshellInput.packages.${system}.default;

  configSrc = pkgs.lib.fileset.toSource {
    root = ./quickshell;
    fileset = ./quickshell;
  };

  # greeter.qml swapped in as shell.qml
  greeterConfigSrc = pkgs.runCommand "teakettler-greeter-config" {} ''
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
in
pkgs.symlinkJoin {
  pname = "teakettler-shell";
  version = qs.version or "unstable";
  paths = [ qs ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    makeWrapper ${pkgs.lib.getExe qs} $out/bin/teakettler \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}"

    makeWrapper ${pkgs.lib.getExe qs} $out/bin/teakettler-greeter \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}" \
      --add-flags '-p ${greeterConfigSrc}'
  '';

  meta = {
    description = "teakettler-shell - quickshell config for mangowc (includes a greetd greeter)";
    mainProgram = "teakettler";
    platforms = pkgs.lib.platforms.linux;
  };
}
