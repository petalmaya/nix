# Builds `kurukurubar` (and `kurukurubar-greeter`) from the vendored
# Quickshell config in ./quickshell - this used to be the flutterquick
# flake's own package output, folded in here so the whole theme lives in
# one repo. Takes `pkgs` and the `quickshell` flake input (the raw
# quickshell package isn't in nixpkgs proper yet) and returns the built
# package, same shape `inputs.flutterquick.packages.${system}.kurukurubar`
# used to be.
#
# IMPORTANT (post-handoff fix): `kurukurubar` is now a THIN ENV WRAPPER
# around the real `qs` binary - it no longer passes `-c <name> -m
# <manifest>` or `-p <store-path>`. It launches bare `qs`, which means it
# resolves config the normal quickshell way: ~/.config/quickshell/shell.qml,
# registered under the name "default". That directory is populated by
# default.nix's `home.file.".config/quickshell"` (an out-of-store symlink
# to this same ./quickshell dir in your actual git checkout, not a copy
# into the Nix store) - see default.nix for why.
#
# This fixes two real bugs from the old `-c kurukurubar -m manifest`
# scheme:
#   1. Running plain `qs`/`quickshell` by hand (not via the wrapper) used
#      to fail with "Could not find default config directory or shell.qml
#      in any path", because nothing ever lived at
#      ~/.config/quickshell - the only usable config was locked inside a
#      Nix store path behind a custom instance name. Now `qs` bare just
#      works, same as any other quickshell setup (e.g. Zaphkiel's).
#   2. Editing QML required a full home-manager rebuild to see anything,
#      since the "config" was a fileset copy into the store. Now it's a
#      live symlink into your working tree - edit and quickshell's own
#      hot-reload (or a `qs ipc call` restart) picks it up immediately.
#
# `qs ipc call ...` binds (see ../niri/default.nix) no longer need `-c
# kurukurubar` either - bare `qs ipc call ...` already targets "default",
# which is what an unnamed instance registers as.
{ pkgs, quickshellInput }:
let
  system = pkgs.stdenv.hostPlatform.system;
  qs = quickshellInput.packages.${system}.default;

  # Still used for the *greeter* build below, which runs as a separate
  # system user with no git checkout to symlink into - that one still
  # needs a real, hermetic, store-built copy of the config. Not used for
  # the main `kurukurubar` wrapper anymore (see module doc comment above).
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

  # greeter.qml swapped in as shell.qml, same trick Zaphkiel's
  # pkgs/kurukurubar.nix uses for its asGreeter derivation - simpler than
  # a manifest with two named entries, and this side genuinely only ever
  # needs one entry point.
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
    # No --add-flags at all now: bare `qs`, resolving
    # ~/.config/quickshell (the out-of-store symlink set up in
    # default.nix) as the "default" instance.
    makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}"

    # Greeter side: no live checkout to symlink into (different user, no
    # $HOME with a git clone), so this one still gets a real built-in
    # config via `-p`, pointed at the greeter-swapped copy above. It's a
    # single dedicated instance with no other process ever needing to
    # `qs ipc call` into it, so an explicit name/manifest was never
    # actually needed here either.
    makeWrapper ${pkgs.lib.getExe qs} $out/bin/kurukurubar-greeter \
      --set FONTCONFIG_FILE "${fontconfig}" \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : "${runtimePath}" \
      --add-flags '-p ${greeterConfigSrc}'
  '';

  meta = {
    description = "Kuru Kuru Bar - Quickshell config for niri/mangowc (vendored in-tree, includes a greetd greeter.qml)";
    mainProgram = "kurukurubar";
    platforms = pkgs.lib.platforms.linux;
  };
}
