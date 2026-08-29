import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Open apps on the left, pinned apps + the launcher shortcut on the
// right - flipped from the first pass per your feedback. Divider only
// shows when both groups actually have something in them, same as
// before, just re-ordered.
RowLayout {
  id: root

  property string outputName: ""
  // Exposed for Layers/Dock.qml so it can hand this row's current pill
  // geometry to Dat.Launcher right before the launcher opens - see the
  // Apps button below and Layers/Launcher.qml's morph-in animation.
  property real pillWidth: 0
  property real pillHeight: 0

  // Mac-style magnify: every DockItem reads this back to compute how
  // close it is to the pointer, in *row-local* coordinates. -1 means
  // "pointer isn't over the row", which every DockItem treats as
  // "no magnification".
  //
  // A HoverHandler here rather than a MouseArea - same reasoning as
  // Layers/Dock.qml's hoverZone: it's non-exclusive, so it keeps
  // reporting position even while a DockItem's own MouseArea
  // underneath has hover/click. A MouseArea covering the row would
  // just steal hover from every DockItem instead.
  readonly property real hoverX: rowHover.hovered ? rowHover.point.position.x : -1

  spacing: 6

  HoverHandler {
    id: rowHover

    target: root
  }

  Repeater {
    model: Dat.Dock.runningModel

    // Flat ListModel roles (appId/key/closing) - bound via required
    // properties on this Item wrapper rather than DockItem itself,
    // since DockItem already declares its own (non-required)
    // appId/closing properties and can't re-declare them as required
    // to receive the row directly. toplevel is resolved fresh via
    // toplevelForKey every time it's needed, instead of being stored/
    // passed around directly - see Data/Dock.qml for why the raw
    // Toplevel object never goes into the ListModel.
    //
    // row.closing is true once the backing toplevel is gone - DockItem
    // handles disabling hover + fading itself out and reports back via
    // Dat.Dock.confirmClosed() when it's actually safe to remove the
    // row (see Data/Dock.qml).
    Item {
      id: row

      required property string appId
      required property bool closing
      required property string key

      implicitHeight: dockItem.implicitHeight
      implicitWidth: dockItem.implicitWidth

      Wid.DockItem {
        id: dockItem

        appId: row.appId
        closing: row.closing
        containerMouseX: root.hoverX
        pinned: false
        rowX: row.x
        toplevel: Dat.Dock.toplevelForKey(row.key)

        onClosingChanged: if (dockItem.closing) closeAnimTimer.restart()

        Timer {
          id: closeAnimTimer

          interval: Dat.MaterialEasing.standardTime
          onTriggered: Dat.Dock.confirmClosed(row.key)
        }
      }
    }
  }

  Rectangle {
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 2
    Layout.rightMargin: 2
    color: Dat.Colors.current.outline_variant
    implicitHeight: 32
    opacity: 0.5
    visible: Dat.Dock.runningModel.count > 0 && Dat.Dock.pinnedEntries.length > 0
    width: 1
  }

  Repeater {
    model: Dat.Dock.pinnedEntries

    Wid.DockItem {
      required property var modelData

      appId: modelData.appId
      containerMouseX: root.hoverX
      pinned: true
    }
  }

  Rectangle {
    id: appsButton

    Layout.alignment: Qt.AlignVCenter
    color: (Dat.Launcher.open && Dat.Launcher.outputName == root.outputName) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container
    implicitHeight: 40
    implicitWidth: 40
    radius: Dat.Radius.lgSm

    Gen.MatIcon {
      anchors.centerIn: parent
      color: (Dat.Launcher.open && Dat.Launcher.outputName == root.outputName) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
      font.pointSize: 16
      icon: "apps"
    }

    Gen.MouseArea {
      layerColor: Dat.Colors.current.on_surface
      layerRadius: 14

      onClicked: Dat.Launcher.toggleFromDock(root.outputName, root.pillWidth, root.pillHeight)
    }
  }
}
