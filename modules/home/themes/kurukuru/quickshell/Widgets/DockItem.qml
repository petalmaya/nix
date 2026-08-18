pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Data as Dat
import qs.Generics as Gen

// Two modes, distinguished by whether `toplevel` is set:
//  - pinned mode (toplevel not set): represents an app, not a specific
//    window - click launches it or focuses whichever window of it was
//    most recently active. Used for Dat.Dock.pinnedEntries.
//  - running mode (toplevel set): represents one specific window - click
//    always focuses that exact toplevel. Used for
//    Dat.Dock.runningModel, which is what gives multiple open windows
//    of the same app their own separate icons.
Item {
  id: root

  required property string appId
  property bool pinned: false
  property var toplevel: null

  readonly property var desktopEntry: Dat.Dock.desktopEntryFor(root.appId)
  readonly property var runningForApp: Dat.Dock.toplevelsByAppId[root.appId.toLowerCase()] ?? []
  readonly property bool isRunning: root.toplevel ? true : root.runningForApp.length > 0
  readonly property bool isFocused: root.toplevel ? !!root.toplevel.activated : root.runningForApp.some(t => t.activated)

  implicitHeight: 48
  implicitWidth: 48

  // Hover lift used to be a `scale` on this whole root Item, which
  // also grew the MouseArea's hit area into the neighbouring icon and
  // caused a hover bounce as adjacent items fought over the overlap.
  // Fix: root stays a fixed 48x48 hit target, only the inner `visual`
  // Item grows on hover.
  Item {
    id: visual

    anchors.centerIn: parent
    height: parent.height
    scale: mArea.containsMouse ? 1.12 : 1
    width: parent.width

    Behavior on scale {
      NumberAnimation {
        duration: Dat.MaterialEasing.emphasizedTime
        easing.bezierCurve: Dat.MaterialEasing.emphasized
      }
    }

    Rectangle {
      id: bg

      anchors.fill: parent
      color: root.isFocused ? Dat.Colors.current.primary_container : Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, mArea.containsMouse ? 1 : 0)
      radius: Dat.Radius.lgSm

      Behavior on color {
        ColorAnimation {
          duration: Dat.MaterialEasing.standardTime
        }
      }
    }

    IconImage {
      id: icon

      anchors.centerIn: parent
      implicitSize: 30
      source: root.desktopEntry ? Quickshell.iconPath(root.desktopEntry.icon, true) : ""

      Gen.MatIcon {
        anchors.centerIn: parent
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: 18
        icon: "apps"
        visible: icon.status != Image.Ready
      }
    }

    // running indicator - a little dot under the icon, doubled-width
    // when this specific window/app currently has focus
    Rectangle {
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 2
      anchors.horizontalCenter: parent.horizontalCenter
      color: root.isFocused ? Dat.Colors.current.primary : Dat.Colors.current.on_surface_variant
      height: 4
      radius: Dat.Radius.full
      visible: root.isRunning
      width: root.isFocused ? 14 : 4

      Behavior on width {
        NumberAnimation {
          duration: Dat.MaterialEasing.standardTime
          easing.bezierCurve: Dat.MaterialEasing.standard
        }
      }
    }
  }

  MouseArea {
    id: mArea

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    anchors.fill: parent
    hoverEnabled: true

    onClicked: mevent => {
      if (mevent.button == Qt.RightButton) {
        // pinning happens from the launcher (Generics/LauncherApps.qml);
        // right-click here is unpin-only
        if (root.pinned) {
          Dat.Dock.unpin(root.appId);
        }
        return;
      }
      if (root.toplevel) {
        Dat.Dock.focusToplevel(root.toplevel);
      } else {
        Dat.Dock.launchOrFocus(root.appId);
      }
    }
  }
}
