//@ pragma Env QSG_RENDER_LOOP=threaded

pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Layers as Lay

// Separate root from shell.qml, per ARCHITECTURE.md's entry-points.
// This is what greetd's default_session.command (or
// scripts/test-greeter.sh) runs - `qs -c nagarebar -p greeter.qml`,
// not shell.qml. No logged-in session yet, so this only pulls in the
// singletons that don't assume a running desktop session
// (Clock/Colors/Config/Greeter/MaterialEasing/Paths).
ShellRoot {
  // Every output gets a Layers/Greeter.qml instance; which one is
  // `primary` is resolved inside that file by following the mouse
  // (its HoverHandler + Data/Greeter.qml's focusedOutput), not via
  // Data/Niri.qml - depending on niri's IPC pre-login is one more
  // thing that can go wrong before you've logged in.
  Variants {
    model: Quickshell.screens

    Lay.Greeter {
    }
  }

  // same "don't nag about hot reload" behavior as shell.qml
  Connections {
    function onReloadCompleted() {
      Quickshell.inhibitReloadPopup();
    }

    function onReloadFailed() {
      Quickshell.inhibitReloadPopup();
    }

    target: Quickshell
  }
}
