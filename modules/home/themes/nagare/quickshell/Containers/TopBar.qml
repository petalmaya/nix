import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Three self-contained "pill" clusters (left/center/right), same
// floating-island language as Layers/Notch.qml, instead of one flat
// row. Each sizes to its own content, so the center pill stays
// centered regardless of how wide the left/right clusters get.
RowLayout {
  id: root

  property string outputName: ""

  spacing: 8

  // Left pill - workspace, media, recording
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Rectangle {
      id: leftPill

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.55)
      height: parent.height
      implicitWidth: leftRow.implicitWidth + 10
      radius: Dat.Radius.full

      RowLayout {
        id: leftRow

        anchors.centerIn: parent
        spacing: 6

        Wid.WorkspacePill {
          outputName: root.outputName
        }

        Wid.MprisDot {
          implicitHeight: 20
          implicitWidth: 20
          outputName: root.outputName
          radius: Dat.Radius.full
        }

        Wid.RecordingDot {
          implicitHeight: 20
          implicitWidth: 20
          outputName: root.outputName
        }
      }
    }
  }

  // Center pill - clock
  Item {
    Layout.fillHeight: true
    Layout.preferredWidth: centerPill.implicitWidth

    Rectangle {
      id: centerPill

      anchors.centerIn: parent
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.55)
      height: parent.height
      implicitWidth: clockText.contentWidth + 28
      radius: Dat.Radius.full

      // TimePill self-anchors (centers itself, positions its own
      // MouseArea off its contentWidth) - a RowLayout parent fought
      // with that, so this is a plain Item instead
      Wid.TimePill {
        id: clockText

        outputName: root.outputName
      }
    }
  }

  // Right pill - notch toggle, battery, quick actions, audio, brightness
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Rectangle {
      id: rightPill

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.55)
      height: parent.height
      implicitWidth: rightRow.implicitWidth + 10
      radius: Dat.Radius.full

      RowLayout {
        id: rightRow

        anchors.centerIn: parent
        layoutDirection: Qt.RightToLeft
        spacing: 6

        Gen.MatIcon {
          Layout.rightMargin: 2
          color: Dat.Colors.current.primary
          font.pointSize: 11
          icon: (Dat.Globals.notchState(root.outputName) == "FULLY_EXPANDED") ? "expand_less" : "expand_more"
          verticalAlignment: Text.AlignVCenter

          MouseArea {
            anchors.fill: parent

            onClicked: mevent => {
              if (Dat.Globals.notchState(root.outputName) == "EXPANDED") {
                Dat.Globals.setNotchState(root.outputName, "FULLY_EXPANDED");
                return;
              }
              Dat.Globals.setNotchState(root.outputName, "EXPANDED");
            }
          }
        }

        Wid.BatteryPill {
          implicitHeight: 20
          outputName: root.outputName
          radius: Dat.Radius.full
        }

        Rectangle {
          color: (Dat.Launcher.open && Dat.Launcher.outputName == root.outputName) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container_high
          implicitHeight: 20
          implicitWidth: 20
          radius: Dat.Radius.full

          Gen.MatIcon {
            anchors.centerIn: parent
            color: (Dat.Launcher.open && Dat.Launcher.outputName == root.outputName) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
            font.pointSize: 11
            icon: "apps"
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: Dat.Radius.full

            onClicked: Dat.Launcher.toggle(root.outputName)
          }
        }

        // quick-options popover (Layers/QuickOptions.qml) - Wi-Fi's
        // standalone icon and Layers/NetPanel.qml got folded into
        // this, see QuickOptionsPanel.qml's "Networks & devices" expander
        Rectangle {
          color: Dat.Globals.quickOptionsOpen(root.outputName) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container_high
          implicitHeight: 20
          implicitWidth: 20
          radius: Dat.Radius.full

          Gen.MatIcon {
            anchors.centerIn: parent
            color: Dat.Globals.quickOptionsOpen(root.outputName) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
            font.pointSize: 11
            icon: "tune"
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: Dat.Radius.full

            onClicked: Dat.Globals.setQuickOptionsOpen(root.outputName, !Dat.Globals.quickOptionsOpen(root.outputName))
          }
        }

        Wid.AudioSwiper {
          implicitHeight: 20
          outputName: root.outputName
          radius: Dat.Radius.full
        }

        Wid.BrightnessDot {
          implicitHeight: 20
          implicitWidth: 20
          radius: Dat.Radius.full
        }
      }
    }
  }
}
