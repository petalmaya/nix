import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen

Rectangle {
  id: root

  required property bool active
  required property string icon
  required property string label

  signal clicked

  color: root.active ? Dat.Colors.current.primary_container : Dat.Colors.current.surface_container
  implicitHeight: 52
  radius: Dat.Radius.lgSm

  Behavior on color {
    ColorAnimation {
      duration: Dat.MaterialEasing.standardTime
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 10

    Gen.MatIcon {
      color: root.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
      font.pointSize: 15
      icon: root.icon
    }

    Text {
      Layout.fillWidth: true
      color: root.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
      elide: Text.ElideRight
      font.pointSize: 10
      text: root.label
    }
  }

  Gen.MouseArea {
    layerColor: root.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
    layerRadius: 14

    onClicked: root.clicked()
  }
}
