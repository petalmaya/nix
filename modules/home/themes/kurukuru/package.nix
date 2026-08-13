# Builds `kurukurubar` (and `kurukurubar-greeter`) from the vendored
# Quickshell config in ./quickshell - this used to be the flutterquick
# flake's own package output, folded in here so the whole theme lives in
# one repo. Takes `pkgs` and the `quickshell` flake input (the raw
# quickshell package isn't in nixpkgs proper yet) and returns the built
# package, same shape `inputs.flutterquick.packages.${system}.kurukurubar`
# used to be.
{ pkgs, quickshellInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qs = quickshellInput.packages.${system}.default;

  # Only the bits quickshell actually needs at runtime - keeps the store
  # path from dragging in unrelated repo files, and doubles as a decent
  # "did I forget to add a new top-level dir" checklist whenever the
  # module map changes.
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

  fontconfig = pkgs.makeFontsConf {
    fontDirectories = [
      pkgs.material-symbols
      pkgs.nerd-fonts.noto
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

  # `qs ipc call ...` with no --config/--path targets the config named
  # "default" (see qs(1): "if --config is not passed, 'default' will be
  # assumed"). Launching via bare `-p ${configSrc}` never registers under
  # that name - configSrc is a /nix/store hash path, so the running
  # instance's config identity is that hash, not "default". That's why
  # every "qs ipc call ..." bind in config.kdl used to silently find
  # nothing to talk to. Fix: give the instance an explicit name via a
  # manifest and launch + all binds (see niri/default.nix) reference that
  # same name with `-c`.
  manifest = pkgs.writeText "kurukurubar-manifest.conf" ''
    kurukurubar = ${configSrc}
    kurukurubar-greeter = ${configSrc}/greeter.qml
  '';
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
      --prefix PATH : "${runtimePath}" \
      --add-flags '-c kurukurubar -m ${manifest}'

    # Same env as the main wrapper, just pointed at greeter.qml instead -
    # this is what services.greetd's `command` line (see
    # modules/nixos/kurukuru-greeter.nix) expects to find on PATH. Kept
    # as a second binary rather than a flag on `kurukurubar` itself so
    # that module's greetd wiring doesn't need to know quickshell's flag
    # syntax at all, just a plain command.
    makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar-greeter \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}" \
      --add-flags '-c kurukurubar-greeter -m ${manifest}'
  '';

  meta = {
    description = "Kuru Kuru Bar - Quickshell config for niri/mangowc (vendored in-tree, includes a greetd greeter.qml)";
    mainProgram = "kurukurubar";
    platforms = pkgs.lib.platforms.linux;
  };
}
