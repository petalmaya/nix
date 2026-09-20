pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

Singleton {
  id: root

  property alias idleInhibited: persist.enabled

  function poweroff() {
    // raw poweroff/reboot binaries need root and fail silently for a
    // normal user - systemctl goes through logind/polkit instead
    Quickshell.execDetached(["systemctl", "poweroff"]);
  }

  function reboot() {
    Quickshell.execDetached(["systemctl", "reboot"]);
  }

  function suspend() {
    // Locks in-process via Data/Globals.qml (see lock request note there).
    Dat.Globals.requestLock();
    Quickshell.execDetached(["systemctl", "suspend"]);
  }

  // Idle inhibit via systemd-inhibit (compositor-agnostic for niri/mangowc).
  function toggleIdle() {
    root.idleInhibited = !root.idleInhibited;
  }

  PersistentProperties {
    id: persist

    property bool enabled: false

    reloadableId: "idleInhibitor"
  }

  Process {
    command: ["systemd-inhibit", "--what=idle", "--who=nixtop-shell", "--why=Manually Blocked Idle", "--mode=block", "sleep", "inf"]
    running: root.idleInhibited
  }
}
