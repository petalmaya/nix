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
    // used to shell out to `qs ipc call lockscreen lock`, same latent
    // bug as the quick-options lock button (Data/Globals.qml) - in-process
    // now
    Dat.Globals.requestLock();
    Quickshell.execDetached(["systemctl", "suspend"]);
  }

  // used to also toggle "hypridle.service", Hyprland's idle daemon -
  // this shell targets niri/mangowc, so that just silently no-op'd.
  // The systemd-inhibit Process below is compositor-agnostic and does
  // the actual work; toggling it is now the whole implementation.
  function toggleIdle() {
    root.idleInhibited = !root.idleInhibited;
  }

  PersistentProperties {
    id: persist

    property bool enabled: false

    reloadableId: "idleInhibitor"
  }

  Process {
    command: ["systemd-inhibit", "--what=idle", "--who=nagarebar", "--why=Manually Blocked Idle", "--mode=block", "sleep", "inf"]
    running: root.idleInhibited
  }
}
