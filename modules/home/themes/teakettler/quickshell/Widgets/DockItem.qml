pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Data as Dat
import qs.Generics as Gen

// Pinned (no toplevel) = app; running (toplevel set) = specific window, one icon each.
Item {
  id: root

  required property string appId
  property bool pinned: false
  property var toplevel: null

  // Row-local pointer x from Containers/Dock.qml's HoverHandler, or -1
  // when the pointer isn't over the row at all.
  property real containerMouseX: -1

  // Row-local x for magnify; running-model wrapper overrides this with its own x.
  property real rowX: root.x

  // Set on toplevel loss; disables hover synchronously to avoid clearHover segfault (see Data/Dock.qml).
  property bool closing: false

  onClosingChanged: if (root.closing) mArea.hoverEnabled = false

  opacity: root.closing ? 0 : 1
  scale: root.closing ? 0.7 : 1

  Behavior on opacity {
    NumberAnimation {
      duration: Dat.MaterialEasing.standardTime
      easing.bezierCurve: Dat.MaterialEasing.standard
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: Dat.MaterialEasing.standardTime
      easing.bezierCurve: Dat.MaterialEasing.standard
    }
  }

  readonly property var desktopEntry: Dat.Dock.desktopEntryFor(root.appId)
  readonly property var runningForApp: Dat.Dock.toplevelsByAppId[root.appId.toLowerCase()] ?? []
  readonly property bool isRunning: root.toplevel ? true : root.runningForApp.length > 0
  readonly property bool isFocused: root.toplevel ? !!root.toplevel.activated : root.runningForApp.some(t => t.activated)

  // Pointer distance to icon center; off-row (-1) reads as infinitely far.
  readonly property real distanceFromPointer: root.containerMouseX < 0 ? Dat.Dock.magnifyRadius : Math.abs((root.rowX + root.width / 2) - root.containerMouseX)

  // Cosine falloff to magnifyRadius; curve tuned by eye, no spec reference.
  readonly property real influence: Math.max(0, Math.cos((Math.min(root.distanceFromPointer, Dat.Dock.magnifyRadius) / Dat.Dock.magnifyRadius) * (Math.PI / 2)))

  implicitHeight: 48
  implicitWidth: 48

  // Root stays a fixed hit target; inner visual scales for magnify and overflows above the bar by design.
  Item {
    id: visual

    anchors.centerIn: parent
    height: parent.height
    scale: 1 + Dat.Dock.magnifyScale * root.influence
    transformOrigin: Item.Bottom
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
    enabled: !root.closing
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
