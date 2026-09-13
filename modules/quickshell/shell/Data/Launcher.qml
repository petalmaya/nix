pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

// Central launcher state (query/mode); new modes need a value here
// plus a branch in Layers/Launcher.qml's Loader.
Singleton {
  id: root

  // name of the mode used when the launcher is first opened / reset
  readonly property string defaultMode: "apps"
  // ordered so Tab can cycle through them - see cycleMode()
  readonly property var modes: ["apps", "wallpaper", "workspaces"]

  property bool open: false
  // which screen currently owns the launcher - only that screen's
  // Layers/Launcher.qml instance actually shows itself
  property string outputName: ""
  property string mode: root.defaultMode
  property string query: ""

  // Dock pill geometry snapshot; Layers/Launcher.qml animates open from this size.
  property real dockOriginWidth: 200
  property real dockOriginHeight: 68

  // True only for dock-click opens; Layers/Launcher.qml skips the grow animation otherwise.
  property bool morphFromDock: false

  // best guess at "the monitor you're on", for calls with no explicit
  // output (e.g. a global IPC keybind). Falls back to the first screen.
  function _guessOutput() {
    if (Dat.MangoWC.active && Dat.MangoWC.focusedOutput) {
      return Dat.MangoWC.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  function show(outputName) {
    root.outputName = outputName || root._guessOutput();
    root.mode = root.defaultMode;
    root.query = "";
    root.morphFromDock = false;
    root.open = true;
  }

  // Via Containers/Dock.qml's Apps button; captures pill size so dockOrigin never reads stale.
  function showFromDock(outputName, pillWidth, pillHeight) {
    if (pillWidth > 0)
      root.dockOriginWidth = pillWidth;
    if (pillHeight > 0)
      root.dockOriginHeight = pillHeight;
    root.outputName = outputName || root._guessOutput();
    root.mode = root.defaultMode;
    root.query = "";
    root.morphFromDock = true;
    root.open = true;
  }

  function hide() {
    root.open = false;
  }

  function toggle(outputName) {
    if (root.open) {
      root.hide();
    } else {
      root.show(outputName);
    }
  }

  function toggleFromDock(outputName, pillWidth, pillHeight) {
    if (root.open) {
      root.hide();
    } else {
      root.showFromDock(outputName, pillWidth, pillHeight);
    }
  }

  // switches mode without closing the launcher
  function setMode(m) {
    root.mode = m;
    root.query = "";
  }

  // Tab cycles forward through `modes`, wrapping - bound to
  // Keys.onTabPressed on the launcher panel
  function cycleMode() {
    const idx = root.modes.indexOf(root.mode);
    const next = root.modes[(idx + 1) % root.modes.length];
    root.setMode(next);
  }

  IpcHandler {
    function toggle() {
      root.toggle("");
    }

    function open() {
      root.show("");
    }

    function close() {
      root.hide();
    }

    target: "launcher"
  }
}
