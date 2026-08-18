pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Widgets as Wid
import qs.Containers as Con

// Per-output surface for greeter.qml. Unlike every other Layers/*.qml,
// this is the whole program - no notch/launcher alongside it, so no
// open/close-linger dance needed. Either mapped for the process's
// whole lifetime, or the process has already exited.
WlrLayershell {
  id: root

  required property ShellScreen modelData
  // whichever output the mouse last entered gets the login card +
  // keyboard focus (see HoverHandler below); falls back to screens[0]
  // until the mouse has moved once
  readonly property bool primary: (Dat.Greeter.focusedOutput === "") ? (root.modelData === Quickshell.screens[0]) : (Dat.Greeter.focusedOutput === (root.modelData?.name ?? ""))

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.primary
  // Exclusive is right for a real greetd session, but it also steals
  // Ctrl+C from the terminal that launched test-greeter.sh - mock mode
  // uses OnDemand instead (same as NetPanel.qml), which only takes
  // focus when GreeterSurface's username field requests it
  keyboardFocus: root.primary ? (Dat.Greeter.mockMode ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukurubar-greeter"
  screen: root.modelData
  surfaceFormat.opaque: false

  // fires on every output regardless of which is primary (pointer
  // motion isn't gated by `focusable`). HoverHandler, not MouseArea,
  // so it doesn't steal clicks from GreeterSurface's own MouseAreas.
  HoverHandler {
    onHoveredChanged: if (this.hovered)
      Dat.Greeter.focusOutput(root.modelData?.name ?? "")
  }

  Loader {
    anchors.fill: parent
    sourceComponent: root.primary ? cardComponent : wallpaperOnlyComponent
  }

  Component {
    id: cardComponent

    Con.GreeterSurface {
    }
  }

  Component {
    id: wallpaperOnlyComponent

    Wid.Wallpaper {
    }
  }
}
