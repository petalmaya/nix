pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

// Central launcher state; new modes also need a branch in Layers/Launcher.qml.
Singleton {
  id: root

  readonly property string defaultMode: "apps"
  // ordered so Tab can cycle through them - see cycleMode()
  readonly property var modes: ["apps", "wallpaper", "workspaces"]

  property bool open: false
  property string outputName: ""
  property string mode: root.defaultMode
  property string query: ""

  // Dock pill geometry snapshot; Layers/Launcher.qml animates open from this size.
  property real dockOriginWidth: 200
  property real dockOriginHeight: 68

  // True only for dock-click opens; Layers/Launcher.qml skips the grow animation otherwise.
  property bool morphFromDock: false

  // Guesses the focused monitor for calls without an output.
  function _guessOutput() {
    if (Dat.Sway.active && Dat.Sway.focusedOutput) {
      return Dat.Sway.focusedOutput;
    }
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

  function setMode(m) {
    root.mode = m;
    root.query = "";
  }

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
