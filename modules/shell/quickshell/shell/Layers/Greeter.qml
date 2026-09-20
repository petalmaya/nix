pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Widgets as Wid
import qs.Containers as Con

// Per-output surface for greeter.qml; the whole program, so no open/close-linger dance needed.
WlrLayershell {
  id: root

  required property ShellScreen modelData
  // Output the mouse last entered gets the card + focus (see HoverHandler); falls back to screens[0].
  readonly property bool primary: (Dat.Greeter.focusedOutput === "") ? (root.modelData === Quickshell.screens[0]) : (Dat.Greeter.focusedOutput === (root.modelData?.name ?? ""))

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.primary
  // Exclusive for real greetd; OnDemand in mock mode so Ctrl+C still works (same as NetPanel.qml).
  keyboardFocus: root.primary ? (Dat.Greeter.mockMode ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "nixtop-shell-greeter"
  screen: root.modelData
  surfaceFormat.opaque: false

  // Fires on every output; HoverHandler, not MouseArea, so it never steals clicks from GreeterSurface.
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
