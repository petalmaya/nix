pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data as Dat

Singleton {
  id: root

  // only one focused toplevel compositor-wide, so this stays global on
  // purpose - every bar showing the same focused app is correct
  property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
  property string hostName: "KuruMi"
  property real mprisDotRotation: 0

  // experimental, not reallllyyy recommended
  property real notchScale: 1

  // --- per-output UI state ---
  // each monitor's notch has its own open/closed state, swipe page,
  // settings tab, hover state, and notification state, keyed by output
  // name (e.g. "eDP-1"), so interacting with one monitor's bar never
  // affects another monitor's bar.
  property var notchStateByOutput: ({})
  property var notchHoveredByOutput: ({})
  property var notifStateByOutput: ({})
  property var settingsTabIndexByOutput: ({})
  property var swipeIndexByOutput: ({})
  property var networkPanelOpenByOutput: ({})
  // quick-options popover (Layers/QuickOptions.qml) - same per-output
  // open/closed pattern as the net panel above, just a separate flag so
  // the two popovers can be shown independently
  property var quickOptionsOpenByOutput: ({})

  function networkPanelOpen(outputName) {
    return root.networkPanelOpenByOutput[outputName] ?? false;
  }

  function setNetworkPanelOpen(outputName, value) {
    const updated = Object.assign({}, root.networkPanelOpenByOutput);
    updated[outputName] = value;
    root.networkPanelOpenByOutput = updated;
  }

  function quickOptionsOpen(outputName) {
    return root.quickOptionsOpenByOutput[outputName] ?? false;
  }

  function setQuickOptionsOpen(outputName, value) {
    const updated = Object.assign({}, root.quickOptionsOpenByOutput);
    updated[outputName] = value;
    root.quickOptionsOpenByOutput = updated;
  }

  function notchState(outputName) {
    return root.notchStateByOutput[outputName] ?? "COLLAPSED";
  }

  function setNotchState(outputName, value) {
    if (root.notchState(outputName) == value)
      return;
    const updated = Object.assign({}, root.notchStateByOutput);
    updated[outputName] = value;
    root.notchStateByOutput = updated;
  }

  function notchHovered(outputName) {
    return root.notchHoveredByOutput[outputName] ?? false;
  }

  function setNotchHovered(outputName, value) {
    const updated = Object.assign({}, root.notchHoveredByOutput);
    updated[outputName] = value;
    root.notchHoveredByOutput = updated;
  }

  function notifState(outputName) {
    return root.notifStateByOutput[outputName] ?? "HIDDEN";
  }

  function setNotifState(outputName, value) {
    const updated = Object.assign({}, root.notifStateByOutput);
    updated[outputName] = value;
    root.notifStateByOutput = updated;
  }

  function settingsTabIndex(outputName) {
    return root.settingsTabIndexByOutput[outputName] ?? 0;
  }

  function setSettingsTabIndex(outputName, value) {
    const updated = Object.assign({}, root.settingsTabIndexByOutput);
    updated[outputName] = value;
    root.settingsTabIndexByOutput = updated;
  }

  function swipeIndex(outputName) {
    return root.swipeIndexByOutput[outputName] ?? 0;
  }

  function setSwipeIndex(outputName, value) {
    const updated = Object.assign({}, root.swipeIndexByOutput);
    updated[outputName] = value;
    root.swipeIndexByOutput = updated;
  }

  // --- lock request (in-process, no shell-out) ---
  // Quick-options' lock button used to shell out to `qs ipc call
  // lockscreen lock` on itself, which failed silently if `qs` wasn't
  // on PATH (see Data/SessionActions.qml for the same execDetached()
  // gotcha). No need to shell out to our own process - just signal
  // Layers/LockScreen.qml directly. External `qs ipc call lockscreen
  // lock` (keybinds, scripts) is untouched, only this internal path.
  signal lockRequested

  function requestLock() {
    root.lockRequested();
  }

  // --- notch IPC (keybindable via `qs ipc call notch <fn>`) ---
  // indices into CentralSwipable.qml's tab model, named so the IPC
  // functions below aren't magic numbers. WorkspacePill.qml hardcodes
  // tabIndexSystem's value (2) directly instead of importing it -
  // keep both in sync if CentralSwipable's tab order ever changes.
  readonly property int tabIndexHome: 0
  readonly property int tabIndexSystem: 2
  readonly property int tabIndexMusic: 3

  // best guess at "the monitor you're on", for IPC calls that don't
  // specify an output. Mirrors Data/Launcher.qml's private copy.
  function _guessOutput() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      return Dat.Niri.focusedOutput;
    }
    if (Dat.MangoWC.active && Dat.MangoWC.focusedOutput) {
      return Dat.MangoWC.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  // opens to full pane on whichever tab was last showing; doesn't
  // touch swipeIndex, so repeat calls land back where you left it.
  function notchOpen(outputName) {
    root.setNotchState(outputName || root._guessOutput(), "FULLY_EXPANDED");
  }

  // Same collapse target onActWinNameChanged uses: EXPANDED if no
  // focused window, COLLAPSED otherwise. With reservedShell on, never
  // let a keybind/IPC close reach COLLAPSED (opacity 0 there just
  // makes the always-reserved bar vanish, and nothing re-expands it) -
  // floor at EXPANDED instead, same as reservedShellChanged below.
  function notchClose(outputName) {
    const output = outputName || root._guessOutput();
    if (Dat.Config.data.reservedShell) {
      root.setNotchState(output, "EXPANDED");
      return;
    }
    root.setNotchState(output, root.actWinName == "desktop" ? "EXPANDED" : "COLLAPSED");
  }

  function notchToggle(outputName) {
    const output = outputName || root._guessOutput();
    if (root.notchState(output) == "FULLY_EXPANDED") {
      root.notchClose(output);
    } else {
      root.notchOpen(output);
    }
  }

  // jumps to a specific tab, always to FULLY_EXPANDED rather than
  // toggling - firing a media/workspace keybind twice should re-affirm
  // that tab, not close the notch.
  function notchOpenTab(outputName, tabIndex) {
    const output = outputName || root._guessOutput();
    root.setSwipeIndex(output, tabIndex);
    root.setNotchState(output, "FULLY_EXPANDED");
  }

  IpcHandler {
    function close() {
      root.notchClose("");
    }

    // jumps to the Home tab (Widgets/HomeView.qml's initialItem) -
    // re-affirming FULLY_EXPANDED also pops any stacked tray menu
    function hello() {
      root.notchOpenTab("", root.tabIndexHome);
    }

    function media() {
      root.notchOpenTab("", root.tabIndexMusic);
    }

    function open() {
      root.notchOpen("");
    }

    function toggle() {
      root.notchToggle("");
    }

    function workspaces() {
      root.notchOpenTab("", root.tabIndexSystem);
    }

    target: "notch"
  }

  // true if any monitor matches the given state/swipe/tab combo - used
  // to throttle background polling (Resources, Clock).
  function anyOutputAt(state, swipeIdx, tabIdx) {
    for (const output in root.notchStateByOutput) {
      if (root.notchStateByOutput[output] !== state)
        continue;
      if (swipeIdx !== undefined && root.swipeIndex(output) !== swipeIdx)
        continue;
      if (tabIdx !== undefined && root.settingsTabIndex(output) !== tabIdx)
        continue;
      return true;
    }
    return false;
  }

  // true if the net panel is open anywhere - lets Data/Network.qml
  // stop polling nmcli when nobody's looking at the wifi list.
  readonly property bool anyNetworkPanelOpen: {
    for (const output in root.networkPanelOpenByOutput) {
      if (root.networkPanelOpenByOutput[output])
        return true;
    }
    return false;
  }

  readonly property bool anyNotCollapsed: {
    for (const output in root.notchStateByOutput) {
      if (root.notchStateByOutput[output] !== "COLLAPSED")
        return true;
    }
    return false;
  }

  // fix: bar started collapsed when reserved shell was turned on (thanks syncqtc)
  Component.onCompleted: {
    Dat.Config.data.reservedShellChanged.connect(() => {
      if (!Dat.Config.data.reservedShell)
        return;
      for (const screen of Quickshell.screens) {
        if (root.notchState(screen.name) == "COLLAPSED") {
          root.setNotchState(screen.name, "EXPANDED");
        }
      }
    });
  }
  onActWinNameChanged: {
    if (Dat.Config.data.reservedShell) {
      return;
    }
    // focus change could be on any monitor, so react uniformly across all of them
    for (const screen of Quickshell.screens) {
      const state = root.notchState(screen.name);
      if (root.actWinName == "desktop" && state == "COLLAPSED") {
        root.setNotchState(screen.name, "EXPANDED");
      } else if (state == "EXPANDED" && !root.notchHovered(screen.name)) {
        root.setNotchState(screen.name, "COLLAPSED");
      }
    }
  }
}
