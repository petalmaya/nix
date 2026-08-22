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

  // Row-local pointer x from Containers/Dock.qml's HoverHandler, or -1
  // when the pointer isn't over the row at all.
  property real containerMouseX: -1

  // Row-local x of this item, for the magnify distance calc below.
  // Defaults to root.x, which is correct when DockItem sits directly
  // in the RowLayout (the pinnedEntries loop in Containers/Dock.qml).
  // The runningModel loop there wraps DockItem in a plain Item to get
  // required-property role binding, which puts an extra coordinate
  // frame between DockItem and the row - that wrapper overrides this
  // with its own x instead, since root.x would otherwise just be 0
  // (DockItem's position *within the wrapper*, not the row).
  property real rowX: root.x

  // Set true by Containers/Dock.qml once this row's toplevel is gone.
  // Disables the MouseArea's hover *synchronously*, before anything
  // destroys this item - letting Qt process a clean hover-leave on a
  // still-alive item instead of segfaulting in
  // QQuickDeliveryAgentPrivate::clearHover on the next mouse event
  // after the delegate is gone. See Data/Dock.qml's _syncRunningModel
  // for the full story.
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

  // Distance from the pointer to this icon's own center, in the same
  // row-local space as containerMouseX. -1 (pointer off the row)
  // reads as "infinitely far", so influence below falls out to 0
  // without a separate branch.
  readonly property real distanceFromPointer: root.containerMouseX < 0 ? Dat.Dock.magnifyRadius : Math.abs((root.rowX + root.width / 2) - root.containerMouseX)

  // 1 dead-center under the pointer, easing down to 0 at
  // magnifyRadius px away. Cosine falloff rather than linear so
  // neighbours taper off instead of the row looking like a tent -
  // ASSUMPTION: no reference for the exact curve/radius, tuned by eye
  // against Data/Dock.qml's magnifyRadius/magnifyScale.
  readonly property real influence: Math.max(0, Math.cos((Math.min(root.distanceFromPointer, Dat.Dock.magnifyRadius) / Dat.Dock.magnifyRadius) * (Math.PI / 2)))

  implicitHeight: 48
  implicitWidth: 48

  // Hover lift used to be a `scale` on this whole root Item, which
  // also grew the MouseArea's hit area into the neighbouring icon and
  // caused a hover bounce as adjacent items fought over the overlap.
  // Fix: root stays a fixed 48x48 hit target, only the inner `visual`
  // Item grows on hover - and now on proximity to the pointer, not
  // just direct hover, for the macOS-style magnify. transformOrigin
  // is pinned to the bottom so icons grow upward off the dock's
  // baseline instead of from their center - the pill itself doesn't
  // clip (see Layers/Dock.qml), so the overflow above the bar is the
  // point, not a bug.
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
