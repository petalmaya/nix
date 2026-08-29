pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

Singleton {
  id: root

  property alias data: jsonData
  property alias fgGenProc: generateFg
  property string wallFg: ""

  FileView {
    path: Dat.Paths.config + "/config.json"
    watchChanges: true

    onAdapterUpdated: writeAdapter()
    onFileChanged: reload()

    JsonAdapter {
      id: jsonData

      property bool matugenEnabled: true
      property bool reservedShell: false
      property bool setWallpaper: true
      property bool wallFgLayer: false
      // Despite the name, this is the lock screen's background now,
      // not a desktop fallback (see wallpaperFor()/lockWallpaper).
      // JSON key stayed "wallSrc" so existing config.json files don't
      // lose their picked image on upgrade.
      property string wallSrc: Quickshell.env("HOME") + "/.config/background"
      // output name -> wallpaper path. Only source for a monitor's
      // desktop background - no shared fallback, each output needs
      // its own entry (via the launcher's "This Display" chip).
      property var wallpapersByOutput: ({})
      property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    }
  }

  // readable alias for wallSrc at call sites that care specifically
  // about the lock screen, not the desktop background
  readonly property alias lockWallpaper: jsonData.wallSrc

  // Resolves the desktop wallpaper for a given output. Strictly
  // per-monitor - no outputName means no wallpaper, not a fallback to
  // the lock screen image (that used to tangle the two together). The
  // one exception: an empty outputName resolves to the lock wallpaper,
  // which is what lets the launcher's "Default" chip
  // (Generics/LauncherWallpaper.qml, targetOutput == "") preview it.
  function wallpaperFor(outputName) {
    if (!outputName) {
      return jsonData.wallSrc;
    }
    if (jsonData.wallpapersByOutput && jsonData.wallpapersByOutput[outputName]) {
      return jsonData.wallpapersByOutput[outputName];
    }
    return "";
  }

  function setWallpaperFor(outputName, path) {
    if (!outputName) {
      jsonData.wallSrc = path;
    } else {
      const updated = Object.assign({}, jsonData.wallpapersByOutput);
      updated[outputName] = path;
      jsonData.wallpapersByOutput = updated;
    }
    // re-theme off whatever was just picked, not just the default -
    // used to only fire via wallSrc's onChanged, so a per-output pick
    // never re-themed at all
    root.runMatugenFor(path);
  }

  function clearWallpaperFor(outputName) {
    if (!outputName || !jsonData.wallpapersByOutput)
      return;
    const updated = Object.assign({}, jsonData.wallpapersByOutput);
    delete updated[outputName];
    jsonData.wallpapersByOutput = updated;
  }

  IpcHandler {
    // sets the lock screen background (not a desktop wallpaper - desktop
    // backgrounds are per-output only now, use setWallpaperFor for those)
    function setWallpaper(path: string) {
      path = Qt.resolvedUrl(path);
      jsonData.wallSrc = path;
      root.runMatugenFor(path);
    }

    // e.g. `qs ipc call config setWallpaperFor eDP-1 /path/to/img.png`
    function setWallpaperFor(outputName: string, path: string) {
      path = Qt.resolvedUrl(path);
      root.setWallpaperFor(outputName, path);
    }

    target: "config"
  }

  Process {
    id: generateFg

    property string script: Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/extractFg.sh"))

    command: ["bash", script, Dat.Paths.urlToPath(jsonData.wallSrc), Dat.Paths.urlToPath(Dat.Paths.cache)]

    stdout: SplitParser {
      onRead: data => {
        if (/\[.*\]/.test(data)) {
          console.log(data);
        } else if (/FOREGROUND/.test(data)) {
          root.wallFg = data.split(" ")[1];
        } else {
          console.log("[EXT] " + data);
        }
      }
    }
  }

  // Runs matugen against whichever wallpaper was just picked (default
  // or per-output) to regenerate the system theme. Non-interactive
  // (applyMatugen.sh skips matugen's color-picker prompt) and fails
  // gracefully if matugen isn't installed.
  property string matugenTargetPath: ""

  Process {
    id: matugenProc

    property string script: Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/applyMatugen.sh"))

    command: ["bash", script, Dat.Paths.urlToPath(root.matugenTargetPath), Dat.Paths.urlToPath(Dat.Paths.cache)]

    stdout: SplitParser {
      onRead: data => console.log("[MATUGEN] " + data)
    }
    stderr: SplitParser {
      onRead: data => console.log("[MATUGEN] " + data)
    }
  }

  function runMatugenFor(path) {
    if (path == "" || !jsonData.matugenEnabled) {
      return;
    }
    root.matugenTargetPath = path;
    if (matugenProc.running) {
      // command already reflects the new path, just needs a restart
      matugenProc.running = false;
    }
    matugenProc.running = true;
  }

  Connections {
    // re-theme immediately if the toggle gets flipped back on
    function onMatugenEnabledChanged() {
      root.runMatugenFor(jsonData.wallSrc);
    }

    function onWallFgLayerChanged() {
      onWallSrcChanged();
    }

    // wallSrc is the lock screen background, so this only extracts a
    // foreground cutout for what's behind the lock screen - it does
    // not fire on per-output desktop wallpaper changes.
    function onWallSrcChanged() {
      if (jsonData.wallSrc != "" && jsonData.wallFgLayer) {
        if (!generateFg.running) {
          generateFg.running = true;
        }
      }
    }

    target: jsonData
  }
}
