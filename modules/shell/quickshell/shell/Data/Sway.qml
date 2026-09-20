pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Sway IPC — event-driven via Go daemon (modules/shell/quickshell/ipc/daemon.go)
// The daemon watches $SWAYSOCK and writes a compact snapshot to
// ~/.cache/nixtop-shell/sway.json. This QML only FileViews that file,
// so we never spawn `swaymsg` per frame. Fallback to direct swaymsg
// polling if the daemon cache is missing (e.g. no Go build).
//
// Shape mirrors MangoWC so widgets can swap backends with minimal changes:
//   active, focusedOutput, currentWorkspace, currentWorkspaceByOutput, workspaces, monitors
Singleton {
  id: root

  property bool active: false
  property string focusedOutput: ""
  property int currentWorkspace: 1
  property var currentWorkspaceByOutput: ({})
  property var monitors: ({})
  property var workspaces: ({})
  property var _raw: []

  // daemon cache path — must match daemon.go default
  readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/nixtop-shell/sway.json"

  function _escape(str) {
    return `'${String(str).replace(/'/g, `'\\''`)}'`;
  }

  function _rebuild(obj) {
    if (!obj || !obj.workspaces) return;
    root.focusedOutput = obj.focusedOutput || ""
    root.currentWorkspace = obj.currentWorkspace || 1
    root.currentWorkspaceByOutput = obj.currentWorkspaceByOutput || {}
    root.workspaces = obj.workspaces || {}
    root._raw = obj._rawWorkspaces || []
    // shape outputs as monitors for compat with MangoWC consumers that iterate monitors
    const mons = {}
    if (obj.outputs) {
      for (const o of obj.outputs) {
        mons[o.name] = {
          name: o.name,
          active: o.active,
          current_workspace: o.current_workspace,
        }
      }
    } else if (obj.currentWorkspaceByOutput) {
      for (const out in obj.currentWorkspaceByOutput) {
        mons[out] = { name: out, active: out === obj.focusedOutput }
      }
    }
    root.monitors = mons
    root.active = true
  }

  // swaymsg wrappers — compositor-agnostic callers use these
  function workspaceFor(outputName) {
    if (outputName && root.currentWorkspaceByOutput[outputName] !== undefined) {
      return root.currentWorkspaceByOutput[outputName]
    }
    return root.currentWorkspace
  }

  function setCurrentTag(idx, outputName) {
    // sway workspaces are global, not per-output tags; focus then workspace
    if (outputName && outputName !== root.focusedOutput) {
      Quickshell.execDetached(["bash", "-c", `swaymsg workspace ${idx} >/dev/null 2>&1 || swaymsg --no-auto-reply workspace number ${idx}`])
      // swaymsg workspace <num> already switches output if that workspace is on another output;
      // for true per-output isolation we also focus output first:
      Quickshell.execDetached(["bash", "-c", `swaymsg focus output ${root._escape(outputName)} >/dev/null 2>&1; swaymsg workspace number ${idx}`])
    } else {
      Quickshell.execDetached(["swaymsg", "workspace", "number", `${idx}`])
    }
  }

  function focusNext(outputName) {
    Quickshell.execDetached(["swaymsg", "workspace", "next"])
  }

  function focusPrev(outputName) {
    Quickshell.execDetached(["swaymsg", "workspace", "prev"])
  }

  // Go daemon cache file — cheap, inotify-driven
  FileView {
    id: cacheView
    path: Qt.resolvedUrl("file://" + root.cachePath)
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: err => {
      // daemon not yet run — trigger fallback poll once, then keep trying
      if (err === FileViewError.FileNotFound) {
        fallbackPoll.running = true
      }
    }
    JsonAdapter {
      id: adapter
      property var snapshot: ({})
      onSnapshotChanged: {
        if (snapshot && snapshot.workspaces) {
          root._rebuild(snapshot)
        }
      }
    }
  }

  // Fallback: poll swaymsg directly if daemon cache missing (no Go build or first boot)
  // This is intentionally slower (500ms) and only runs when FileView fails.
  Process {
    id: fallbackPoll
    running: false
    // only run when no active snapshot and sway socket exists
    command: ["bash", "-c", "command -v swaymsg >/dev/null 2>&1 && swaymsg -t get_workspaces 2>/dev/null | jq -c '{workspaces: ., focusedOutput: \"\", currentWorkspace: 1}' || echo '{}'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.length === 0) return
        try {
          const obj = JSON.parse(data)
          // crude fallback: synthesize workspaces map from get_workspaces array
          if (obj && Array.isArray(obj.workspaces)) {
            const byOutput = {}
            const wsMap = {}
            let focused = ""
            let cur = 1
            for (const w of obj.workspaces) {
              const key = `${w.output}-${w.num}`
              wsMap[key] = { idx: w.num, output: w.output, is_focused: w.focused, is_active: w.visible, is_urgent: w.urgent }
              if (w.visible) byOutput[w.output] = w.num
              if (w.focused) { focused = w.output; cur = w.num }
            }
            root.focusedOutput = focused
            root.currentWorkspace = cur
            root.currentWorkspaceByOutput = byOutput
            root.workspaces = wsMap
            root.active = Object.keys(wsMap).length > 0
          }
        } catch (e) {}
      }
    }
    onExited: (code, status) => {
      // retry every 2s while cache still missing
      if (!root.active) {
        retryTimer.restart()
      }
    }
  }

  Timer {
    id: retryTimer
    interval: 2000
    onTriggered: {
      if (!root.active) {
        cacheView.reload()
        if (!root.active) fallbackPoll.running = true
      }
    }
  }

  // daemon launcher — start nixtop-sway-ipc if available and sway socket exists
  // The binary is `nixtop-sway-ipc` from package.nix (Go build) or fallback to `swaymsg` loop above.
  Process {
    id: daemonProc
    command: ["bash", "-c", "command -v nixtop-sway-ipc >/dev/null 2>&1 && test -n \"$SWAYSOCK\" && exec nixtop-sway-ipc || exit 0"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") === "sway" || Quickshell.env("SWAYSOCK") !== ""
    stdout: SplitParser { onRead: data => console.log("[SWAY-IPC] " + data) }
    stderr: SplitParser { onRead: data => console.log("[SWAY-IPC] " + data) }
  }

  // also watch SWAYSOCK env to auto-enable under swayfx
  Component.onCompleted: {
    // try to load cache immediately if it exists
    cacheView.reload()
  }
}
