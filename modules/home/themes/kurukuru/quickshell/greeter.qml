//@ pragma Env QSG_RENDER_LOOP=threaded

pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Layers as Lay

// Separate root from shell.qml, per ARCHITECTURE.md's entry-points
// section. This is what greetd's `default_session.command` (or
// scripts/test-greeter.sh, for testing) actually runs - `qs -c
// kurukurubar -p greeter.qml`, not the usual shell.qml. There's no
// logged-in session yet at this point: no lock screen, no launcher, no
// niri/mangowc IPC guaranteed to be up (depends how the greetd session
// is configured - see handoff.md's Greeter session for the assumptions
// this makes and what's untested), so this deliberately only pulls in
// Data.Clock/Colors/Config/Greeter/MaterialEasing/Paths - the singletons
// that don't assume a running desktop session.
ShellRoot {
  // Every connected output gets a Layers/Greeter.qml instance so
  // secondary monitors aren't left blank. Which one is `primary` (shows
  // the actual login card + takes keyboard focus) is resolved inside
  // Layers/Greeter.qml itself now - it follows the mouse (see that
  // file's HoverHandler + Data/Greeter.qml's focusedOutput), starting
  // from screens[0] before the first hover event. Not resolved here via
  // Data/Niri.qml the way Data/Launcher.qml resolves its focused output,
  // since there's no window-focus concept pre-login, and depending on
  // niri's own IPC being up during the greeter session specifically is
  // one more thing that can go wrong before you've even logged in.
  Variants {
    model: Quickshell.screens

    Lay.Greeter {
    }
  }

  // same "don't nag about hot reload" behavior as shell.qml - harmless
  // here too if you're iterating on this file live via
  // scripts/test-greeter.sh
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
