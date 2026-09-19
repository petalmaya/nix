import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Three pills (left/center/right) sized to content so center stays centered.
RowLayout {
  id: root

  property string outputName: ""

  spacing: 8

  // Left pill - launcher, workspace, media, recording (Ambxst: logo + dots left)
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Rectangle {
      id: leftPill

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.85)
      height: parent.height
      implicitWidth: leftRow.implicitWidth + 10
      radius: Dat.Radius.full

      RowLayout {
        id: leftRow

        anchors.centerIn: parent
        spacing: 6

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

  // Center pill - clock (Ambxst: time centered)
  Item {
    Layout.fillHeight: true
    Layout.preferredWidth: centerPill.implicitWidth

    Rectangle {
      id: centerPill

      anchors.centerIn: parent
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.85)
      height: parent.height
      implicitWidth: clockText.contentWidth + 28
      radius: Dat.Radius.full

      // Plain Item wrapper; RowLayout conflicts with TimePill self-anchoring.
      Wid.TimePill {
        id: clockText

        outputName: root.outputName
      }
    }
  }

  // Right pill - status cluster (Ambxst: wifi/bt/audio/battery/clock/power right)
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Rectangle {
      id: rightPill

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.85)
      height: parent.height
      implicitWidth: rightRow.implicitWidth + 10
      radius: Dat.Radius.full

      RowLayout {
        id: rightRow

        anchors.centerIn: parent
        layoutDirection: Qt.RightToLeft
        spacing: 6

        // Power menu shortcut (Ambxst top-right power icon)
        Rectangle {
          color: Dat.Colors.current.surface_container_high
          implicitHeight: 20
          implicitWidth: 20
          radius: Dat.Radius.full

          Gen.MatIcon {
            anchors.centerIn: parent
            color: Dat.Colors.current.on_surface
            font.pointSize: 11
            icon: "power_settings_new"
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: Dat.Radius.full

            onClicked: {
              Dat.Globals.setNotchState(root.outputName, "FULLY_EXPANDED");
              Dat.Globals.setSwipeIndex(root.outputName, 4);
              Dat.Globals.setSettingsTabIndex(root.outputName, 0);
            }
          }
        }

        // Wi-Fi state dot (Ambxst quick-toggle row mirrored in the bar)
        Rectangle {
          color: Dat.Network.wifiEnabled ? Dat.Colors.current.primary : Dat.Colors.current.surface_container_high
          implicitHeight: 20
          implicitWidth: 20
          radius: Dat.Radius.full

          Gen.MatIcon {
            anchors.centerIn: parent
            color: Dat.Network.wifiEnabled ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
            font.pointSize: 11
            icon: Dat.Network.wifiEnabled ? "wifi" : "wifi_off"
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: Dat.Radius.full

            onClicked: Dat.Globals.setQuickOptionsOpen(root.outputName, !Dat.Globals.quickOptionsOpen(root.outputName))
          }
        }

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

        // Quick-options popover; Wi-Fi/NetPanel folded into QuickOptionsPanel expander.
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
