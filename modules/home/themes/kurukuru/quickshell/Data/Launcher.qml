pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

// Central state for the app launcher popup. Own singleton (not just a
// bool on Globals.qml) since it carries more state - search query,
// mode - and is meant to grow: adding a mode means adding a value here
// and a branch in Layers/Launcher.qml's Loader, nothing else.
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

  // best guess at "the monitor you're on", for calls with no explicit
  // output (e.g. a global IPC keybind). Falls back to the first screen.
  function _guessOutput() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      return Dat.Niri.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  function show(outputName) {
    root.outputName = outputName || root._guessOutput();
    root.mode = root.defaultMode;
    root.query = "";
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
