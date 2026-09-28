pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data as Dat

Singleton {
  id: root

  // Single focused toplevel compositor-wide, so every bar shows the same app.
  property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
  property string hostName: "Nagare"
  property real mprisDotRotation: 0

  // Global UI scale multiplier; experimental, expect rough edges.
  property real notchScale: 1

  property var notchStateByOutput: ({})
  property var notchHoveredByOutput: ({})
  property var notifStateByOutput: ({})
  property var settingsTabIndexByOutput: ({})
  property var swipeIndexByOutput: ({})
  property var networkPanelOpenByOutput: ({})
  // Quick-options popover (Layers/QuickOptions.qml); separate flag so both popovers stay independent.
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

  // In-process lock request; shelling out to our own IPC fails when `qs` is missing from PATH.
  signal lockRequested

  function requestLock() {
    root.lockRequested();
  }

  // Indices into CentralSwipable.qml's tabs; WorkspacePill.qml hardcodes tabIndexSystem (2), keep in sync.
  readonly property int tabIndexHome: 0
  readonly property int tabIndexSystem: 2
  readonly property int tabIndexMusic: 3

  // Guesses the focused monitor for IPC calls without an output.
  function _guessOutput() {
    if (Dat.Sway.active && Dat.Sway.focusedOutput) {
      return Dat.Sway.focusedOutput;
    }
    if (Dat.MangoWC.active && Dat.MangoWC.focusedOutput) {
      return Dat.MangoWC.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  // Opens to the last tab without touching swipeIndex.
  function notchOpen(outputName) {
    root.setNotchState(outputName || root._guessOutput(), "FULLY_EXPANDED");
  }

  // With reservedShell on, floor at EXPANDED so the reserved bar never vanishes.
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

  // Always expands to the tab; repeat keybinds re-affirm instead of toggling closed.
  function notchOpenTab(outputName, tabIndex) {
    const output = outputName || root._guessOutput();
    root.setSwipeIndex(output, tabIndex);
    root.setNotchState(output, "FULLY_EXPANDED");
  }

  IpcHandler {
    function close() {
      root.notchClose("");
    }

    // Re-affirming FULLY_EXPANDED pops any stacked tray menu.
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

  // Throttles Resources/Clock polling to visible outputs.
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

  // Lets Network.qml stop nmcli polling when no panel is open.
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
