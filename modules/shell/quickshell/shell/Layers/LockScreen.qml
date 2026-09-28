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
  // Restores every monitor's pre-lock bar state on unlock.
  property var prevStateByOutput: ({})

  // Shared by both lock triggers so the double-invocation guard lives in one place.
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
