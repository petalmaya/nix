pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// Same shape as Layers/NetPanel.qml (full-screen click-off catcher +
// top-right popover) - kept as its own layershell rather than folding
// into NetPanel so the two can be open independently and don't share
// close/animation state.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Globals.quickOptionsOpen(root.modelData?.name ?? "")
  property bool surfaceVisible: false

  function close() {
    Dat.Globals.setQuickOptionsOpen(root.modelData?.name ?? "", false);
    // don't leave the embedded network section "open" (and its
    // background wifi/bluetooth polling running) once the whole popover
    // is dismissed - same idea as its onNetworkExpandedChanged handler
    content.networkExpanded = false;
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
  namespace: "kurukuru-quickoptions"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
    } else {
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
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    height: content.implicitHeight + 28
    implicitWidth: 280
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

    MouseArea {
      anchors.fill: parent
    }

    Gen.QuickOptionsPanel {
      id: content

      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.top: parent.top
      anchors.topMargin: 14
      outputName: root.modelData?.name ?? ""
    }
  }
}
