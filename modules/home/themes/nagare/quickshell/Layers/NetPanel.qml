pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth

import qs.Data as Dat
import qs.Generics as Gen

// SUPERSEDED: Wi-Fi's bar icon now opens Layers/QuickOptions.qml,
// whose "Networks & devices" expander embeds the same
// Generics/NetworkPanel.qml content in place instead of a popup.
// Unregistered from shell.qml, left in place in case you want it back -
// re-add `Lay.NetPanel { modelData: scopeRoot.modelData }` to shell.qml
// and the wifi icon to Containers/TopBar.qml.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Globals.networkPanelOpen(root.modelData?.name ?? "")
  // stays true through the close animation, mirrors the notch's own
  // visible/PropertyAction dance for its transitions
  property bool surfaceVisible: false

  function close() {
    Dat.Globals.setNetworkPanelOpen(root.modelData?.name ?? "", false);
    // NetworkPanel.qml isn't torn down on close (no Loader), so
    // nothing else stops a bluetooth scan it started
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

  // covers the whole output; click outside the panel closes it, Esc
  // does the same via the focus scope below
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
    // constant-alpha translucency, same as Launcher.qml - no
    // desktop-vs-window state to key off here
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
