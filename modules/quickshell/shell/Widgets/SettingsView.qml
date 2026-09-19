pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Ambxst-style settings: Power (profiles/battery), Audio (PipeWire),
// Theme (matugen/wallpaper/shell reserve), System (toggles/advanced).
Item {
  id: root

  property string outputName: ""

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: this.spacing
    spacing: 3

    Item {
      Layout.fillWidth: true
      Layout.leftMargin: 20
      Layout.rightMargin: 20
      implicitHeight: 18

      RowLayout {
        id: tabLay

        property int activeIndex: Dat.Globals.settingsTabIndex(root.outputName)

        anchors.fill: parent

        Repeater {
          // Wallpaper picker lives in Generics/LauncherWallpaper.qml launcher mode.
          model: ["Power", "Audio", "Theme", "System"]

          Item {
            id: tabRect

            required property int index
            required property string modelData

            Layout.fillHeight: true
            Layout.fillWidth: true
            state: (index == tabLay.activeIndex) ? "ACTIVE" : "INACTIVE"

            states: [
              State {
                name: "ACTIVE"

                PropertyChanges {
                  bgRect.opacity: 1
                  tabText.opacity: 1
                }
              },
              State {
                name: "INACTIVE"

                PropertyChanges {
                  bgRect.opacity: 0
                  tabText.opacity: 0.8
                }
              }
            ]
            transitions: [
              Transition {
                from: "INACTIVE"
                to: "ACTIVE"

                NumberAnimation {
                  duration: Dat.MaterialEasing.emphasizedAccelTime
                  easing.bezierCurve: Dat.MaterialEasing.emphasizedAccel
                  properties: "bgRect.opacity,tabText.opacity"
                }
              },
              Transition {
                from: "ACTIVE"
                to: "INACTIVE"

                NumberAnimation {
                  duration: Dat.MaterialEasing.emphasizedDecelTime
                  easing.bezierCurve: Dat.MaterialEasing.emphasizedDecel
                  properties: "bgRect.opacity,tabText.opacity"
                }
              }
            ]

            Rectangle {
              id: bgRect

              anchors.centerIn: parent
              color: Dat.Colors.current.surface_container_high
              height: tabRect.height
              radius: Dat.Radius.mdSm
              width: tabText.contentWidth + 20
            }

            Text {
              id: tabText

              anchors.centerIn: parent
              color: Dat.Colors.current.on_surface
              horizontalAlignment: Text.AlignHCenter
              text: parent.modelData
              verticalAlignment: Text.AlignVCenter

              Behavior on opacity {
                NumberAnimation {
                  duration: Dat.MaterialEasing.emphasizedTime
                  easing.bezierCurve: Dat.MaterialEasing.emphasized
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onClicked: mevent => {
                  Dat.Globals.setSettingsTabIndex(root.outputName, tabRect.index);
                }
              }
            }
          }
        }
      }
    }

    StackLayout {
      Layout.fillHeight: true
      Layout.fillWidth: true
      currentIndex: tabLay.activeIndex

      Wid.PowerTab {
        Layout.fillHeight: true
        Layout.fillWidth: true
        opacity: visible ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: Dat.MaterialEasing.standardAccelTime
            easing.bezierCurve: Dat.MaterialEasing.standardAccel
          }
        }
      }

      Wid.AudioTab {
        Layout.fillHeight: true
        Layout.fillWidth: true
        opacity: visible ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: Dat.MaterialEasing.emphasizedAccelTime
            easing.bezierCurve: Dat.MaterialEasing.emphasizedAccel
          }
        }
      }

      // Network tab placeholder; no backend yet.
      Wid.AdvancedTab {
        opacity: visible ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: Dat.MaterialEasing.emphasizedAccelTime
            easing.bezierCurve: Dat.MaterialEasing.emphasizedAccel
          }
        }
      }

      // Theme tab (Ambxst settings panel): matugen + wallpaper + shell reserve.
      Rectangle {
        color: Dat.Colors.current.surface_container_high
        radius: Dat.Radius.xl
        opacity: visible ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: Dat.MaterialEasing.emphasizedAccelTime
            easing.bezierCurve: Dat.MaterialEasing.emphasizedAccel
          }
        }

        Flickable {
          anchors.fill: parent
          anchors.margins: 10
          clip: true
          contentHeight: themeCol.height

          ColumnLayout {
            id: themeCol

            width: parent.width
            spacing: 8

            Gen.TweakToggle {
              Layout.fillWidth: true
              active: Dat.Config.data.matugenEnabled
              text: "Matugen theming"

              onClicked: () => Dat.Config.data.matugenEnabled = !Dat.Config.data.matugenEnabled
            }

            Gen.TweakToggle {
              Layout.fillWidth: true
              active: Dat.Config.data.wallFgLayer
              text: "Fg Layer Extraction"

              onClicked: () => Dat.Config.data.wallFgLayer = !Dat.Config.data.wallFgLayer
            }

            Gen.TweakToggle {
              Layout.fillWidth: true
              active: Dat.Config.data.reservedShell
              text: "Exclusive Shell"

              onClicked: () => Dat.Config.data.reservedShell = !Dat.Config.data.reservedShell
            }

            Text {
              Layout.fillWidth: true
              color: Dat.Colors.current.on_surface_variant
              font.pointSize: 9
              text: "Wallpapers: " + Dat.Config.data.wallpaperDir
              wrapMode: Text.Wrap
            }
          }
        }
      }

    }
  }
}
