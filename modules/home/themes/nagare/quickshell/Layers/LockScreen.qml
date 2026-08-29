pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import Quickshell
import Quickshell.Io

import qs.Data as Dat
import qs.Containers as Con

Scope {
  id: root

  property alias lock: lock
  // output name -> notchState it had right before we locked, so unlocking
  // restores every monitor's bar to how it was, not just one
  property var prevStateByOutput: ({})

  // shared by both trigger paths below (external `qs ipc call lockscreen
  // lock`, and the in-process Globals.lockRequested signal the
  // quick-options lock button now uses) so the double-invocation guard
  // only has to live in one place
  function doLock() {
    if (lock.locked || locker.running) {
      return;
    }

    const saved = {};
    for (const screen of Quickshell.screens) {
      saved[screen.name] = Dat.Globals.notchState(screen.name);
      Dat.Globals.setNotchState(screen.name, "COLLAPSED");
    }
    root.prevStateByOutput = saved;
    locker.start();
  }

  Connections {
    function onLockRequested() {
      root.doLock();
    }

    target: Dat.Globals
  }

  WlSessionLock {
    id: lock

    onLockedChanged: {
      if (lock.locked)
        return;
      for (const screen of Quickshell.screens) {
        const prev = root.prevStateByOutput[screen.name] ?? "COLLAPSED";
        Dat.Globals.setNotchState(screen.name, prev);
      }
    }

    Con.LockScreenSurface {
      lock: lock
    }
  }

  IpcHandler {
    // external trigger - `qs ipc call lockscreen lock` (or `quickshell
    // ipc call lockscreen lock`, depending what your Quickshell install
    // actually names its CLI - see Globals.qml's lockRequested comment)
    // from outside the running shell process, e.g. a niri keybind
    function lock() {
      root.doLock();
    }

    function unlock() {
      lock.locked = false;
    }

    target: "lockscreen"
  }

  Timer {
    id: locker

    interval: 250

    onTriggered: lock.locked = true
  }
}
