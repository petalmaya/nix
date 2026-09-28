import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Containers as Con

// Floating pill with no exclusion zone; input stays masked to the edge and pill.

WlrLayershell {
  id: root

  required property ShellScreen modelData

  // Desktop-focus trigger is debounced via desktopSettled; actWinName can blip - hover reveals stay instant.
  readonly property bool desktopFocused: Dat.Globals.actWinName == "desktop"
  property bool desktopSettled: false

  // Force the dock closed whenever the launcher is open here so both surfaces never show at once.
  readonly property bool launcherOpenHere: Dat.Launcher.open && Dat.Launcher.outputName == (root.modelData?.name ?? "")

  // Only revealEdge may initiate a reveal; hoverTarget only sustains an already-open dock.
  readonly property bool revealed: !root.launcherOpenHere && (root.desktopSettled || root.contactMade)

  property bool contactMade: false

  Connections {
    function onContainsMouseChanged() {
      if (revealEdge.containsMouse)
        root.contactMade = true;
    }

    target: revealEdge
  }

  Connections {
    function onHoveredChanged() {
      if (!hoverZone.hovered && !revealEdge.containsMouse)
        root.contactMade = false;
    }

    target: hoverZone
  }

  onDesktopFocusedChanged: desktopSettleTimer.restart()

  Component.onCompleted: root.desktopSettled = root.desktopFocused

  Timer {
    id: desktopSettleTimer

    interval: 150

    onTriggered: root.desktopSettled = root.desktopFocused
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: false
  implicitHeight: 84
  layer: WlrLayer.Top
  namespace: "nagare-dock"
  screen: root.modelData
  surfaceFormat.opaque: false

  onRevealedChanged: {
    if (root.revealed) {
      hideTimer.stop();
    } else {
      hideTimer.restart();
    }
  }

  // Skip hide debounce for the launcher case - the pill must clear immediately to avoid overlap.
  onLauncherOpenHereChanged: {
    if (root.launcherOpenHere) {
      hideTimer.stop();
      pill.forceHidden = true;
    }
  }

  // Only the edge and hover target accept input, never the live pill.
  mask: Region {
    Region {
      item: revealEdge
    }

    Region {
      item: hoverTarget
    }
  }

  // Debounces hide only - showing is instant, matching the notch's hover reveal.
  Timer {
    id: hideTimer

    interval: 400

    onTriggered: {
      if (!root.revealed) {
        pill.forceHidden = true;
      }
    }
  }

  // Separate from `revealed` so re-showing cancels the pending hide instead of waiting for hideTimer.
  Connections {
    function onRevealedChanged() {
      if (root.revealed)
        pill.forceHidden = false;
    }

    target: root
  }

  MouseArea {
    id: revealEdge

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    height: 2
    hoverEnabled: true
    width: pill.width
  }

  // Same footprint as `pill` but pinned at the revealed position; a stationary target avoids reveal/hide stutter.
  Item {
    id: hoverTarget

    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter
    height: pill.height
    width: pill.width
  }

  // HoverHandler, not MouseArea: MouseArea hover is exclusive and would bounce the pill; HoverHandler is non-exclusive.
  HoverHandler {
    id: hoverZone

    target: hoverTarget
  }

  Rectangle {
    id: pill

    property bool forceHidden: false

    anchors.bottom: parent.bottom
    anchors.bottomMargin: forceHidden ? -(height + 4) : 10
    anchors.horizontalCenter: parent.horizontalCenter
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    height: dockRow.implicitHeight + 16
    opacity: forceHidden ? 0 : 1
    radius: Dat.Radius.xl
    width: dockRow.implicitWidth + 16

    Behavior on anchors.bottomMargin {
      NumberAnimation {
        duration: Dat.MaterialEasing.emphasizedTime
        easing.bezierCurve: Dat.MaterialEasing.emphasized
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    Behavior on width {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    Con.Dock {
      id: dockRow

      anchors.centerIn: parent
      outputName: root.modelData?.name ?? ""
      pillHeight: pill.height
      pillWidth: pill.width
    }
  }
}
