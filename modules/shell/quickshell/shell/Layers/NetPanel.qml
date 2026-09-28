pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth

import qs.Data as Dat
import qs.Generics as Gen

// SUPERSEDED by Layers/QuickOptions.qml expander (same Generics/NetworkPanel.qml content).
// Unregistered from shell.qml; re-add there plus the wifi icon to Containers/TopBar.qml to restore.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Globals.networkPanelOpen(root.modelData?.name ?? "")
  // Lingers mapped through the close animation like the notch.
  property bool surfaceVisible: false

  function close() {
    Dat.Globals.setNetworkPanelOpen(root.modelData?.name ?? "", false);
    // No Loader tears NetworkPanel down on close, so close must stop its scans.
    if (Bluetooth.defaultAdapter?.discovering) {
      Bluetooth.defaultAdapter.discovering = false;
    }
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.open
  keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "nagare-netpanel"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
    } else {
      // let the close animation on `panel` finish before unmapping
      closeLinger.restart();
    }
  }

  Timer {
    id: closeLinger

    interval: Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Item {
    id: focusScope

    anchors.fill: parent
    focus: root.open

    Keys.onEscapePressed: root.close()
  }

  Rectangle {
    id: panel

    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.top: parent.top
    anchors.topMargin: 34
    // Constant translucency; no desktop-vs-window state exists here.
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    height: content.height + 28
    implicitWidth: 320
    opacity: root.open ? 1 : 0
    radius: Dat.Radius.xl
    scale: root.open ? 1 : 0.88
    transformOrigin: Item.TopRight

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

    Gen.NetworkPanel {
      id: content

      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.top: parent.top
      anchors.topMargin: 14
    }
  }
}
