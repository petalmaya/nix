import QtQuick
import QtQuick.Controls
import qs.Data as Dat

Item {
  id: popupRect

  property alias closeTimer: popupClose
  property bool closed: true
  property var currentNotif: stack.currentItem
  property string outputName: ""

  function pushNotif(e) {
    if (Dat.NotifServer.dndEnabled) {
      return;
    }
    if (!e) {
      return;
    }
    let notification = Qt.createComponent("../Generics/NotificationPopup.qml");
    stack.push(notification, {
      "notif": e,
      "width": stack.width,
      "implicitHeight": stack.height,
      "view": stack,
      "popup": popupRect
    });
    if (Dat.Globals.notifState(popupRect.outputName) == "HIDDEN") {
      Dat.Globals.setNotifState(popupRect.outputName, "POPUP");
      popupRect.closed = false;
      popupClose.start();
    } else if (Dat.Globals.notifState(popupRect.outputName) == "POPUP") {
      popupRect.closed = false;
      popupClose.restart();
    }
  }

  // Named (not inline) so it can be disconnected in onDestruction below -
  // Popup.qml is instantiated per-screen, but NotifServer.server is a
  // singleton, so a screen going away (monitor unplugged, Variants
  // rebuilding) left its old handler connected to a now-destroyed
  // popupRect, which is where the "pushNotif of object [null]" spam
  // came from.
  function onNotifServerNotification(e) {
    popupRect.pushNotif(e);

    // issue #30 where spotify updates a notification
    e.bodyChanged.connect(() => popupRect.pushNotif(e));
    e.summaryChanged.connect(() => popupRect.pushNotif(e));
  }

  Component.onCompleted: {
    Dat.NotifServer.server.onNotification.connect(popupRect.onNotifServerNotification);

    stack.depthChanged.connect(() => {
      if (stack.depth == 0 && Dat.Globals.notifState(popupRect.outputName) == "POPUP") {
        popupClose.running = false;
        Dat.Globals.setNotifState(popupRect.outputName, "HIDDEN");
      }
    });
  }

  Component.onDestruction: {
    Dat.NotifServer.server.onNotification.disconnect(popupRect.onNotifServerNotification);
  }

  StackView {
    id: stack

    anchors.fill: parent
    clip: true
    initialItem: null

    pushEnter: Transition {
      ParallelAnimation {
        YAnimator {
          duration: Dat.MaterialEasing.standardDecelTime
          easing.bezierCurve: Dat.MaterialEasing.standardDecel
          from: 100
          to: 0
        }
      }
    }
    pushExit: Transition {
      ParallelAnimation {
        YAnimator {
          duration: Dat.MaterialEasing.standardAccelTime
          easing.bezierCurve: Dat.MaterialEasing.standardAccel
          from: 0
          to: -100
        }

        NumberAnimation {
          duration: Dat.MaterialEasing.standardAccelTime
          easing.bezierCurve: Dat.MaterialEasing.standardAccel
          from: 1
          property: "opacity"
          to: 0
        }
      }
    }
  }

  Timer {
    id: popupClose

    interval: 3500

    onTriggered: {
      popupRect.closed = true;
      if (Dat.Globals.notifState(popupRect.outputName) != "INBOX") {
        Dat.Globals.setNotifState(popupRect.outputName, "HIDDEN");
      }
    }
  }

  Timer {
    id: stackClearTimer

    interval: 500
    running: Dat.Globals.notifState(popupRect.outputName) == "HIDDEN"

    onTriggered: stack.clear()
  }
}
