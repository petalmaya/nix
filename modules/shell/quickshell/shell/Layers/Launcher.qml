pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// Logical open state; surfaceVisible lingers so the close animation finishes.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Launcher.open && Dat.Launcher.outputName == (root.modelData?.name ?? "")
  // Lingers through the close animation so it is never cut short.
  property bool surfaceVisible: false

  function close() {
    Dat.Launcher.hide();
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.open
  // Exclusive grabs focus on map so typing works immediately; OnDemand raced content.requestFocus().
  keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "nagare-launcher"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
      content.requestFocus();
      // First focus request can land before mapping, so retry shortly after.
      refocusTimer.restart();
    } else {
      closeLinger.restart();
    }
  }

  Timer {
    id: refocusTimer

    interval: 30

    onTriggered: content.requestFocus()
  }

  Timer {
    id: closeLinger

    // Longer linger only for morph-from-dock close so the shrink-back finishes; keybind close just fades.
    interval: Dat.Launcher.morphFromDock ? Dat.MaterialEasing.standardTime : Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Rectangle {
    id: panel

    // Focus lives on panel (an ancestor of the TextInput) so unaccepted keys bubble up naturally.
    focus: root.open

    Keys.onEscapePressed: root.close()
    // Traps Tab focus inside the panel.
    Keys.onTabPressed: event => {
      Dat.Launcher.cycleMode();
      content.requestFocus();
      event.accepted = true;
    }

    anchors.bottom: parent.bottom
    // Fixed to screen height so the search field stays pinned as results resize the panel.
    anchors.bottomMargin: parent.height * 0.01
    anchors.horizontalCenter: parent.horizontalCenter
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    height: root.open ? (modeSwitcher.height + content.implicitHeight + 12 + 10 + 12) : (Dat.Launcher.morphFromDock ? Dat.Launcher.dockOriginHeight : (modeSwitcher.height + content.implicitHeight + 12 + 10 + 12))
    implicitWidth: root.open ? 560 : (Dat.Launcher.morphFromDock ? Dat.Launcher.dockOriginWidth : 560)
    opacity: Dat.Launcher.morphFromDock ? 1 : (root.open ? 1 : 0)
    radius: Dat.Radius.xl
    transformOrigin: Item.Bottom

    Behavior on height {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    Behavior on implicitWidth {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    // swallow clicks so they don't fall through to the close-catcher
    MouseArea {
      anchors.fill: parent
    }

    // Fades contents separately from panel geometry so the list never visibly squashes mid-morph.
    Item {
      id: chrome

      anchors.fill: parent
      opacity: root.open ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
          easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
        }
      }

      // Mode switch keeps the panel open.
      Row {
        id: modeSwitcher

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 12
        spacing: 6

        Repeater {
          model: [{
              "mode": "apps",
              "icon": "apps"
            }, {
              "mode": "wallpaper",
              "icon": "wallpaper"
            }, {
              "mode": "workspaces",
              "icon": "grid_view"
            }]

          Rectangle {
            id: modeTab

            required property var modelData

            color: (Dat.Launcher.mode == modelData.mode) ? Dat.Colors.current.surface_container_highest : "transparent"
            height: 28
            radius: Dat.Radius.mdSm
            width: 28

            Gen.MatIcon {
              anchors.centerIn: parent
              color: (modeTab.modelData.mode == Dat.Launcher.mode) ? Dat.Colors.current.primary : Dat.Colors.current.on_surface_variant
              font.pointSize: Dat.Type.labelMedium
              icon: modeTab.modelData.icon
            }

            Gen.MouseArea {
              layerColor: Dat.Colors.current.on_surface
              layerRadius: Dat.Radius.mdSm

              onClicked: {
                Dat.Launcher.setMode(modeTab.modelData.mode);
                content.requestFocus();
              }
            }
          }
        }
      }

      Loader {
        id: content

        function requestFocus() {
          if (content.item && content.item.requestFocus) {
            content.item.requestFocus();
          }
        }

        readonly property real implicitHeight: item ? item.implicitHeight : 0

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: modeSwitcher.bottom
        anchors.topMargin: 10
        sourceComponent: {
          if (Dat.Launcher.mode == "wallpaper")
            return wallpaperMode;
          if (Dat.Launcher.mode == "workspaces")
            return workspacesMode;
          return appsMode;
        }
      }
    }

    Component {
      id: appsMode

      Gen.LauncherApps {
      }
    }

    Component {
      id: wallpaperMode

      Gen.LauncherWallpaper {
      }
    }

    Component {
      id: workspacesMode

      Gen.LauncherWorkspaces {
      }
    }
  }
}
