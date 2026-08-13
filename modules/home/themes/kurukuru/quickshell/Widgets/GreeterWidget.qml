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

    // plain rounded-rect clip, not a real alpha-mask shape - ClippingRectangle
    // is the built-in Quickshell.Widgets equivalent for that case, cheaper
    // than a MultiEffect mask (no second offscreen texture for the mask
    // source, just a clip). See handoff.md Session 18.
    ClippingRectangle {
      anchors.fill: parent
      color: "transparent"
      radius: 20

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
    radius: 20

    Text {
      anchors.centerIn: parent
      color: Dat.Colors.current.on_surface
      font.pointSize: 14
      text: "Hello cutie"
    }
  }
}
