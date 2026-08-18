pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// `open`/`surfaceVisible` split used by every Layers/*.qml surface:
// `open` is logical state, `surfaceVisible` is what layershell reads
// for `visible` and stays true a bit longer via closeLinger so the
// close animation finishes before the surface actually disappears.
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
  // Exclusive forces focus the instant the surface maps, so typing
  // works immediately - OnDemand only grabs focus when something
  // inside asks, which raced against content.requestFocus() below
  keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukuru-launcher"
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

    interval: Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  // covers the whole output; click outside the panel closes it
  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Rectangle {
    id: panel

    // used to live on a separate sibling Item, which raced the search
    // field's TextInput for focus on every open. panel is an actual
    // ancestor of the TextInput, so this is now the only focus claim,
    // and unaccepted key events bubble up to it naturally
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
    // fixed relative to screen height, not the panel's own height -
    // pins the search field as results grow/shrink, since only
    // `height` changes and the bottom edge stays put
    anchors.bottomMargin: parent.height * 0.01
    anchors.horizontalCenter: parent.horizontalCenter
    // same withAlpha strategy as Layers/Notch.qml - tinted, not opaque
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    // 12 (top margin to modeSwitcher) + 28 (modeSwitcher height) + 10
    // (gap to content) + 12 (bottom padding to match the original
    // content-only 24px), see modeSwitcher/content anchoring below
    height: modeSwitcher.height + content.implicitHeight + 12 + 10 + 12
    implicitWidth: 560
    opacity: root.open ? 1 : 0
    radius: Dat.Radius.xxl
    scale: root.open ? 1 : 0.92
    transformOrigin: Item.Bottom

    Behavior on opacity {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on height {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    // swallow clicks so they don't fall through to the close-catcher
    MouseArea {
      anchors.fill: parent
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

          color: (Dat.Launcher.mode == modelData.mode) ? Dat.Colors.current.primary_container : "transparent"
          height: 28
          radius: Dat.Radius.mdSm
          width: 28

          Gen.MatIcon {
            anchors.centerIn: parent
            color: (modeTab.modelData.mode == Dat.Launcher.mode) ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface_variant
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
