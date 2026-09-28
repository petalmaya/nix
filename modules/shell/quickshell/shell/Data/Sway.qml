pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Event-driven Sway IPC via the Go daemon cache, shaped to match MangoWC.
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
      // swaymsg switches output implicitly, so focus output first for per-output isolation.
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

  // Slow swaymsg fallback polling only while the daemon cache file is missing.
  Process {
    id: fallbackPoll
    running: false
    command: ["bash", "-c", "command -v swaymsg >/dev/null 2>&1 && swaymsg -t get_workspaces 2>/dev/null | jq -c '{workspaces: ., focusedOutput: \"\", currentWorkspace: 1}' || echo '{}'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.length === 0) return
        try {
          const obj = JSON.parse(data)
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

  // Starts nixtop-sway-ipc when available and a sway socket exists.
  Process {
    id: daemonProc
    command: ["bash", "-c", "command -v nixtop-sway-ipc >/dev/null 2>&1 && test -n \"$SWAYSOCK\" && exec nixtop-sway-ipc || exit 0"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") === "sway" || Quickshell.env("SWAYSOCK") !== ""
    stdout: SplitParser { onRead: data => console.log("[SWAY-IPC] " + data) }
    stderr: SplitParser { onRead: data => console.log("[SWAY-IPC] " + data) }
  }

  // also watch SWAYSOCK env to auto-enable under swayfx
  Component.onCompleted: {
    cacheView.reload()
  }
}
