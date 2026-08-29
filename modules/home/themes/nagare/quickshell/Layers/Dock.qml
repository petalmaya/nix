import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Containers as Con

// Floating bottom dock - translucent pill, no exclusion zone, floats
// over windows instead of reserving space.
//
// Auto-hide: simpler than Notch.qml's velocity tracking - just "mouse
// over the hot edge, over the pill, or desktop focused" -> show, with
// a short hide delay to avoid flicker on quick pass-throughs.
//
// Input is masked to the hot edge + pill bounds (see `mask` below);
// the rest of the layer surface is visual-only and never blocks clicks.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  // actWinName can blip (focus-follows-mouse quirks, a client
  // redrawing) without you doing anything, so the desktop-focus
  // trigger gets debounced through desktopSettled - hover reveals stay
  // instant, only this one waits out a sub-150ms flicker.
  readonly property bool desktopFocused: Dat.Globals.actWinName == "desktop"
  property bool desktopSettled: false

  // Opening the launcher used to leave the dock's `revealed` state
  // alone (mouse still over the hot edge), so both surfaces showed at
  // once. Force the dock closed whenever the launcher is open here
  // instead of relying on z-order (which was never the actual problem).
  readonly property bool launcherOpenHere: Dat.Launcher.open && Dat.Launcher.outputName == (root.modelData?.name ?? "")

  // Only revealEdge (the flush-to-the-literal-bottom-pixel strip) may
  // *initiate* a reveal. hoverTarget spans nearly the whole pill
  // footprint, so letting it initiate too meant hovering anywhere in
  // the lower ~80px of the screen popped the dock open - it only gets
  // a say in *sustaining* an already-open dock (so moving the mouse up
  // onto the visible pill doesn't immediately re-trigger the hide
  // timer).
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

  // Skip the usual hide debounce for the launcher case - it's already
  // animating in immediately, so a lingering pill is the overlap we're
  // trying to avoid, not a flicker worth guarding against.
  onLauncherOpenHereChanged: {
    if (root.launcherOpenHere) {
      hideTimer.stop();
      pill.forceHidden = true;
    }
  }

  // Only revealEdge and hoverTarget accept input, not the live `pill`
  // item - see hoverTarget's comment below for why.
  mask: Region {
    Region {
      item: revealEdge
    }

    Region {
      item: hoverTarget
    }
  }

  // debounces the hide only - showing is always instant (revealed just
  // flips true the moment the mouse enters the strip or the desktop
  // gets focus), matching how the notch itself reveals on hover
  Timer {
    id: hideTimer

    interval: 400

    onTriggered: {
      if (!root.revealed) {
        pill.forceHidden = true;
      }
    }
  }

  // separate from `revealed` so showing again (hoverZone re-entered, or
  // a window closes back to desktop) cancels the pending hide instead of
  // waiting for hideTimer's last-scheduled fire
  Connections {
    function onRevealedChanged() {
      if (root.revealed)
        pill.forceHidden = false;
    }

    target: root
  }

  // Thin always-on strip so the pill can reveal itself even while
  // hidden - the only part of the dock that accepts input outside the
  // pill's own bounds. Flush against the literal bottom edge and no
  // wider than the pill itself (notch-style), so it takes an actual
  // touch of the screen edge under the dock to wake it, not just a
  // pass through the general bottom-of-screen area.
  MouseArea {
    id: revealEdge

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    height: 2
    hoverEnabled: true
    width: pill.width
  }

  // Same footprint as `pill`, but pinned at the fully-revealed
  // position instead of following its slide animation. Used to be
  // `anchors.fill: pill` directly, which lagged behind the cursor
  // mid-slide and caused a reveal/hide stutter as containsMouse
  // flipped back and forth. A stationary target fixes that.
  Item {
    id: hoverTarget

    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter
    height: pill.height
    width: pill.width
  }

  // HoverHandler, not MouseArea: MouseArea hover is exclusive, so
  // hovering an actual icon would steal it from hoverTarget underneath
  // and start the hide timer mid-hover, sliding the pill down into the
  // icon then back up - an infinite bounce. HoverHandler is
  // non-exclusive and keeps reporting regardless of what's on top.
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
    radius: Dat.Radius.xxl
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
      // pill's own width/height, handed back down so the Apps button's
      // click handler can snapshot them into Dat.Launcher right before
      // opening - see Layers/Launcher.qml's morph-in animation.
      pillHeight: pill.height
      pillWidth: pill.width
    }
  }
}
