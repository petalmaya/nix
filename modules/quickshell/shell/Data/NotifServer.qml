// Custom notification server; read before reusing elsewhere.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
  id: notif

  property bool dndEnabled: false
  property int notifCount: notifServer.trackedNotifications.values.length
  property ScriptModel notifications: serverNotifications
  property NotificationServer server: notifServer

  function clearNotifs() {
    [...notifServer.trackedNotifications.values].forEach(elem => {
      elem.dismiss();
    });
  }

  // qs ipc call notifications clear - bindable in niri/mangowc same as
  // "launcher"/"lockscreen" targets elsewhere in Data/
  IpcHandler {
    function clear() {
      notif.clearNotifs();
    }

    target: "notifications"
  }

  NotificationServer {
    id: notifServer

    actionIconsSupported: true
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: n => n.tracked = true
  }

  ScriptModel {
    id: serverNotifications

    values: [...notifServer.trackedNotifications.values].reverse()
  }
}
