import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Data as Dat

RowLayout {
  id: root

  spacing: 10

  Item {
    Layout.leftMargin: 10
    implicitHeight: this.implicitWidth
    implicitWidth: 90

    // ClippingRectangle clip; cheaper than a MultiEffect mask (no second texture).
    ClippingRectangle {
      anchors.fill: parent
      color: "transparent"
      radius: Dat.Radius.xl

      Image {
        id: faceIcon

        anchors.fill: parent
        mipmap: true
        source: Quickshell.env("HOME") + "/.face.icon"

        // stops ugly emptyness when there is no ~/.face.icon
        onStatusChanged: {
          if (faceIcon.status == Image.Error) {
            source = Dat.Paths.getPath(faceIcon, "https://i.pinimg.com/736x/8e/56/1a/8e561a4d6d29e03a93f261eea13a6fe0.jpg");
          }
        }
      }
    }
  }

  Rectangle {
    id: informationREct

    Layout.fillHeight: true
    Layout.fillWidth: true
    color: Dat.Colors.current.surface_container
    radius: Dat.Radius.xl

    Text {
      anchors.centerIn: parent
      color: Dat.Colors.current.on_surface
      font.pointSize: 14
      text: "Hello cutie"
    }
  }
}
