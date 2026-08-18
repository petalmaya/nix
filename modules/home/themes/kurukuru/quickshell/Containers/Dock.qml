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

  spacing: 6

  Repeater {
    model: Dat.Dock.runningModel

    // modelData only ever carries appId + a plain string key (see
    // Data/Dock.qml) - never the live Toplevel object itself. toplevel
    // is resolved fresh here via toplevelForKey every time it's needed,
    // instead of being stored/passed around directly.
    Wid.DockItem {
      required property var modelData

      appId: modelData.appId
      pinned: false
      toplevel: Dat.Dock.toplevelForKey(modelData.key)
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
      pinned: true
    }
  }

  Rectangle {
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

      onClicked: Dat.Launcher.toggle(root.outputName)
    }
  }
}
