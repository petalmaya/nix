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
      property bool wallFgLayer: false
      // Lock screen background. Key stayed "wallSrc" so existing config.json files keep their image.
      property string wallSrc: Quickshell.env("HOME") + "/.config/background"
      // Output name -> desktop wallpaper path. Desktops are drawn by swaybg
      // (scripts/wallpaper.sh), this map is just the state it reads.
      property var wallpapersByOutput: ({})
      property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    }
  }

  // Lock-screen alias for wallSrc at call sites.
  readonly property alias lockWallpaper: jsonData.wallSrc

  // Desktop wallpaper for an output, "" when it has none. Empty outputName
  // resolves to the lock image so the launcher's lock chip can preview it.
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
      root.retheme(path);
    } else {
      const updated = Object.assign({}, jsonData.wallpapersByOutput);
      updated[outputName] = path;
      jsonData.wallpapersByOutput = updated;
      root.applyWallpapers(path);
    }
  }

  function clearWallpaperFor(outputName) {
    if (!outputName || !jsonData.wallpapersByOutput)
      return;
    const updated = Object.assign({}, jsonData.wallpapersByOutput);
    delete updated[outputName];
    jsonData.wallpapersByOutput = updated;
    root.applyWallpapers("");
  }

  IpcHandler {
    // Lock-screen background (desktops are per-output only, use setWallpaperFor).
    function setWallpaper(path: string) {
      path = Qt.resolvedUrl(path);
      jsonData.wallSrc = path;
      root.retheme(path);
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

  // swaybg + matugen live in scripts/wallpaper.sh. The wallpapers map goes
  // over argv as JSON so the script never races config.json's write-back.
  property string wallpaperScript: Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/wallpaper.sh"))

  Process {
    id: wallpaperProc

    stdout: SplitParser {
      onRead: data => console.log("[WALLPAPER] " + data)
    }
    stderr: SplitParser {
      onRead: data => console.log("[WALLPAPER] " + data)
    }
  }

  function runWallpaper(args) {
    wallpaperProc.command = ["bash", root.wallpaperScript].concat(args);
    if (wallpaperProc.running)
      wallpaperProc.running = false;
    wallpaperProc.running = true;
  }

  // Redraw all desktops via swaybg, re-theme off the just-picked image.
  function applyWallpapers(rethemePath) {
    const map = JSON.stringify(jsonData.wallpapersByOutput ?? {});
    const retheme = (rethemePath && jsonData.matugenEnabled) ? Dat.Paths.urlToPath(rethemePath) : "";
    root.runWallpaper(["apply", map, retheme]);
  }

  // Lock-screen picks only re-theme, swaybg is untouched.
  function retheme(path) {
    if (!jsonData.matugenEnabled)
      return;
    root.runWallpaper(["retheme", Dat.Paths.urlToPath(path)]);
  }

  Connections {
    // Re-theme immediately if the toggle gets flipped back on.
    function onMatugenEnabledChanged() {
      root.retheme(jsonData.wallSrc);
    }

    function onWallFgLayerChanged() {
      onWallSrcChanged();
    }

    // Foreground cutout follows the lock image only, not desktop picks.
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
