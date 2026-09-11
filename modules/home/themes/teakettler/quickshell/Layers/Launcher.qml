pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// `open` is logical state, `surfaceVisible` lingers via closeLinger so the close animation finishes first.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Launcher.open && Dat.Launcher.outputName == (root.modelData?.name ?? "")
  // stays mapped through the close animation, same pattern as
  // NetPanel/Notch - visible flipping instantly would cut it short
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
      // surface isn't guaranteed fully mapped the same tick, so the
      // immediate focus request can land too early - retry shortly after
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

  // covers the whole output; click outside the panel closes it
  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Rectangle {
    id: panel

    // Focus lives on panel (an ancestor of the TextInput) so unaccepted keys bubble up naturally.
    focus: root.open

    Keys.onEscapePressed: root.close()
    // Tab cycles apps/wallpaper mode, accepted here so it never tabs
    // focus out of the panel
    Keys.onTabPressed: event => {
      Dat.Launcher.cycleMode();
      content.requestFocus();
      event.accepted = true;
    }

    anchors.bottom: parent.bottom
    // Fixed to screen height so the search field stays pinned as results resize the panel.
    anchors.bottomMargin: parent.height * 0.01
    anchors.horizontalCenter: parent.horizontalCenter
    // Same tint as Layers/Notch.qml and the dock pill (Layers/Dock.qml); geometry alone sells the morph.
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    // Only collapses to dock-pill size when morphFromDock; otherwise stays full size and opacity carries the fade.
    height: root.open ? (modeSwitcher.height + content.implicitHeight + 12 + 10 + 12) : (Dat.Launcher.morphFromDock ? Dat.Launcher.dockOriginHeight : (modeSwitcher.height + content.implicitHeight + 12 + 10 + 12))
    implicitWidth: root.open ? 560 : (Dat.Launcher.morphFromDock ? Dat.Launcher.dockOriginWidth : 560)
    // Only the dock-morph open skips this - see the opacity binding
    // below for the non-morph path's fade.
    opacity: Dat.Launcher.morphFromDock ? 1 : (root.open ? 1 : 0)
    radius: Dat.Radius.xxl
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

    // Only animates on the non-morph path; dock-morph stays at 1 so geometry sells the transition.
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

      // setMode() clears query but leaves open/outputName alone, so
      // switching tabs doesn't close the panel
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
              font.pointSize: 13
              icon: modeTab.modelData.icon
            }

            Gen.MouseArea {
              layerColor: Dat.Colors.current.on_surface
              layerRadius: 10

              onClicked: {
                Dat.Launcher.setMode(modeTab.modelData.mode);
                content.requestFocus();
              }
            }
          }
        }
      }

      // a future mode just adds a branch here and its own
      // Generics/Launcher*.qml - everything else stays untouched
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
