pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

Singleton {
  id: root

  property alias idleInhibited: persist.enabled

  function poweroff() {
    // systemctl goes through logind/polkit; raw power binaries fail silently unprivileged.
    Quickshell.execDetached(["systemctl", "poweroff"]);
  }

  function reboot() {
    Quickshell.execDetached(["systemctl", "reboot"]);
  }

  function suspend() {
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
