# builds kurukurubar (+ greeter) from the vendored ./quickshell config.
# kurukurubar itself is a thin wrapper around bare `qs`, which resolves
# ~/.config/quickshell (the out-of-store symlink set up in default.nix).
# the greeter gets a real store-built copy instead since it runs as its
# own user with no checkout to symlink into
{ pkgs, quickshellInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qs = quickshellInput.packages.${system}.default;

  configSrc = pkgs.lib.fileset.toSource {
    root = ./quickshell;
    fileset = pkgs.lib.fileset.unions [
      ./quickshell/shell.qml
      ./quickshell/greeter.qml
      ./quickshell/Data
      ./quickshell/Layers
      ./quickshell/Containers
      ./quickshell/Widgets
      ./quickshell/Generics
      ./quickshell/Assets
      ./quickshell/scripts
    ];
  };

  # greeter.qml swapped in as shell.qml
  greeterConfigSrc = pkgs.runCommand "kurukurubar-greeter-config" {} ''
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
  ];

  runtimePath = pkgs.lib.makeBinPath [
    pkgs.rembg
    pkgs.brightnessctl
    pkgs.power-profiles-daemon
  ];
in
pkgs.symlinkJoin {
  pname = "kurukurubar";
  version = qs.version or "unstable";
  paths = [ qs ];
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}"

    makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar-greeter \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}" \
      --add-flags '-p ${greeterConfigSrc}'
  '';

  meta = {
    description = "Kuru Kuru Bar - Quickshell config for niri/mangowc (includes a greetd greeter)";
    mainProgram = "kurukurubar";
    platforms = pkgs.lib.platforms.linux;
  };
}
