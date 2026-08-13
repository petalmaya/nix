pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Widgets as Wid
import qs.Containers as Con

// Per-output surface for greeter.qml. Unlike every other Layers/*.qml in
// this tree, this one is the whole program (see greeter.qml) - there's
// no notch/launcher/etc. running alongside it, so it doesn't need the
// open/close-linger dance CLAUDE.md describes for the logged-in shell's
// panels. It's either mapped for the process's entire lifetime, or the
// process has already exited (greetd killed it post-launch).
WlrLayershell {
  id: root

  required property ShellScreen modelData
  // Whichever output the mouse most recently entered gets the login
  // card + keyboard focus (see the HoverHandler below and
  // Data/Greeter.qml's focusedOutput) - falls back to screens[0] until
  // the mouse has actually moved once, so there's always exactly one
  // primary surface even before any hover event has fired.
  readonly property bool primary: (Dat.Greeter.focusedOutput === "") ? (root.modelData === Quickshell.screens[0]) : (Dat.Greeter.focusedOutput === root.modelData.name)

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.primary
  // Exclusive is right for a real greetd session (nothing else is
  // running to steal focus back to), but it also means the terminal
  // that launched scripts/test-greeter.sh stops receiving Ctrl+C - the
  // whole compositor's keyboard goes to this surface instead. Mock mode
  // uses OnDemand instead (same as Layers/NetPanel.qml), which only
  // takes focus when something inside actively requests it
  // (GreeterSurface's username field does, via forceActiveFocus()) and
  // gives it back more cooperatively - Escape below is a second way out
  // either way.
  keyboardFocus: root.primary ? (Dat.Greeter.mockMode ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukurubar-greeter"
  screen: root.modelData
  surfaceFormat.opaque: false

  // Pointer motion isn't gated by `focusable` (that's keyboard-only), so
  // this fires on every output regardless of which one is currently
  // primary - a HoverHandler is used instead of a MouseArea specifically
  // because it doesn't grab/consume the event, so it can sit underneath
  // GreeterSurface's own MouseAreas (text fields, Login button, session
  // picker) without stealing clicks from them.
  HoverHandler {
    onHoveredChanged: if (this.hovered)
      Dat.Greeter.focusOutput(root.modelData.name)
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
