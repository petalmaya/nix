//@ pragma Env QSG_RENDER_LOOP=threaded

pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Layers as Lay

// Separate greetd entry point (`qs -c teakettler -p greeter.qml`); only session-independent singletons.
ShellRoot {
  // One Layers/Greeter.qml per output; primary follows the mouse, not Data/Niri.qml pre-login.
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
