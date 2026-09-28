import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

RowLayout {
  id: root

  property string outputName: ""
  property real pillWidth: 0
  property real pillHeight: 0

  // Row-local pointer x (-1 off-row); HoverHandler keeps hover non-exclusive.
  readonly property real hoverX: rowHover.hovered ? rowHover.point.position.x : -1

  spacing: 6

  HoverHandler {
    id: rowHover

    target: root
  }

  Repeater {
    model: Dat.Dock.runningModel

    // Wrapper binds ListModel roles DockItem cannot redeclare; closing fades via confirmClosed.
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
      font.pointSize: Dat.Type.titleMedium
      icon: "apps"
    }

    Gen.MouseArea {
      layerColor: Dat.Colors.current.on_surface
      layerRadius: Dat.Radius.lgSm

      onClicked: Dat.Launcher.toggleFromDock(root.outputName, root.pillWidth, root.pillHeight)
    }
  }
}
