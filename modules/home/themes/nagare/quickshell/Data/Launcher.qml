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

  // Snapshot of the dock pill's geometry at the moment it was clicked
  // - Layers/Launcher.qml animates its panel open from this size
  // instead of just popping in, so it reads as the pill morphing into
  // the launcher instead of one hiding while the other appears.
  property real dockOriginWidth: 200
  property real dockOriginHeight: 68

  // Only true when this open came from actually clicking the dock's
  // Apps button - see showFromDock(). The IPC keybind (a global
  // shortcut, not a click on a visible pill) has nothing on screen to
  // morph out of, so Layers/Launcher.qml skips the grow animation
  // entirely for that path rather than animating from a stale/default
  // dockOrigin size that doesn't correspond to anything visible - that
  // mismatch, not the animation's actual cost, was the "launcher feels
  // slower now" complaint.
  property bool morphFromDock: false

  // best guess at "the monitor you're on", for calls with no explicit
  // output (e.g. a global IPC keybind). Falls back to the first screen.
  function _guessOutput() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      return Dat.Niri.focusedOutput;
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

  // Called by Containers/Dock.qml's Apps button instead of show() -
  // takes the pill's current width/height right along with opening, so
  // there's no window where dockOrigin could be read stale.
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
