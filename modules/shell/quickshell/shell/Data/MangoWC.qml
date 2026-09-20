pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Mango IPC — event-driven via Go daemon (modules/shell/quickshell/ipc/daemon.go
// mango mode). The daemon watches `mmsg watch all-monitors` and writes a
// compact snapshot to ~/.cache/nixtop-shell/mango.json. This QML only
// FileViews that file, so per-event JSON parsing stays in Go instead of
// blocking the QML thread. Falls back to a direct `mmsg watch` subprocess
// when the daemon cache is missing (first boot, no Go build).
//
// Shape mirrors Data/Sway.qml so widgets swap backends with minimal changes:
//   active, focusedOutput, currentWorkspace, currentWorkspaceByOutput, workspaces, monitors
// First active tag reads as current.
Singleton {
  id: root

  // true once we've actually heard from a running mango instance
  property bool active: false
  // name of mango's currently focused output
  property string focusedOutput: ""
  // idx (1-based) of the focused output's primary active tag, 0 = overview
  property int currentWorkspace: 1
  // output name -> idx of that output's primary active tag
  property var currentWorkspaceByOutput: ({})
  // output name -> raw monitor JSON from mmsg (tags, active_tags,
  // active_client, layout_symbol, keymode, ...)
  property var monitors: ({})
  // "<output>-<tagIndex>" workspaces shaped like Niri.workspaces, plus mango is_active/is_urgent extras.
  property var workspaces: ({})

  // daemon cache path — must match daemon.go mango default
  readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/nixtop-shell/mango.json"

  function _escape(str) {
    return `'${String(str).replace(/'/g, `'\\''`)}'`;
  }

  function _rebuild(monitorList) {
    const mons = {};
    const wsByOutput = {};
    const ws = {};
    let focused = root.focusedOutput;
    let focusedIdx = root.currentWorkspace;

    for (const m of monitorList) {
      mons[m.name] = m;

      const activeTags = m.active_tags || [];
      const primary = activeTags.length ? activeTags[0] : 0;
      wsByOutput[m.name] = primary;

      for (const tag of (m.tags || [])) {
        ws[`${m.name}-${tag.index}`] = {
          idx: tag.index,
          output: m.name,
          is_focused: !!(m.active && tag.is_active),
          name: null,
          is_active: tag.is_active,
          is_urgent: tag.is_urgent,
          client_count: tag.client_count,
          layout: tag.layout
        };
      }

      if (m.active) {
        focused = m.name;
        focusedIdx = primary;
      }
    }

    root.monitors = mons;
    root.currentWorkspaceByOutput = wsByOutput;
    root.workspaces = ws;
    root.focusedOutput = focused;
    root.currentWorkspace = focusedIdx;
  }

  // tag idx active on the given output, falling back to the focused
  // output's idx if we don't have per-output data yet
  function workspaceFor(outputName) {
    if (outputName && root.currentWorkspaceByOutput[outputName] !== undefined) {
      return root.currentWorkspaceByOutput[outputName];
    }
    return root.currentWorkspace;
  }

  // focusmon is a no-op when already focused, so always safe to chain
  function setCurrentTag(idx, outputName) {
    if (outputName && outputName !== root.focusedOutput) {
      Quickshell.execDetached(["bash", "-c", `mmsg dispatch focusmon,${root._escape(outputName)} && mmsg dispatch view,${idx}`]);
    } else {
      Quickshell.execDetached(["mmsg", "dispatch", `view,${idx}`]);
    }
  }

  function focusNext(outputName) {
    if (outputName && outputName !== root.focusedOutput) {
      Quickshell.execDetached(["bash", "-c", `mmsg dispatch focusmon,${root._escape(outputName)} && mmsg dispatch viewtoright`]);
    } else {
      Quickshell.execDetached(["mmsg", "dispatch", "viewtoright"]);
    }
  }

  function focusPrev(outputName) {
    if (outputName && outputName !== root.focusedOutput) {
      Quickshell.execDetached(["bash", "-c", `mmsg dispatch focusmon,${root._escape(outputName)} && mmsg dispatch viewtoleft`]);
    } else {
      Quickshell.execDetached(["mmsg", "dispatch", "viewtoleft"]);
    }
  }

  Process {
    id: fallbackWatch
    // Fallback when the daemon cache is missing (no Go build or first boot).
    // Skipped where mmsg is absent; avoids forking bash for a doomed process.
    // Stops itself once the cache takes over (see cacheView adapter).
    command: ["bash", "-c", "command -v mmsg >/dev/null 2>&1 && exec mmsg watch all-monitors || exit 0"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") === "mango"

    stdout: SplitParser {
      onRead: line => {
        if (!line || line.length === 0)
          return;

        // Cache already live — fallback is stale, stand down.
        if (root.active && adapter.snapshot && adapter.snapshot.timestamp)
          return;

        let data;
        try {
          data = JSON.parse(line);
        } catch (e) {
          return;
        }

        if (!data.monitors)
          return;

        root.active = true;
        root._rebuild(data.monitors);
      }
    }
  }

  // Go daemon cache file — cheap, inotify-driven (primary path)
  FileView {
    id: cacheView
    path: Qt.resolvedUrl("file://" + root.cachePath)
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: err => {
      // daemon not yet run — fallback watcher above keeps us live
      if (err === FileViewError.FileNotFound) {
        fallbackWatch.running = Quickshell.env("XDG_CURRENT_DESKTOP") === "mango";
        retryTimer.restart();
      }
    }
    JsonAdapter {
      id: adapter
      property var snapshot: ({})
      onSnapshotChanged: {
        if (snapshot && snapshot.workspaces) {
          root.focusedOutput = snapshot.focusedOutput || "";
          root.currentWorkspace = snapshot.currentWorkspace || 1;
          root.currentWorkspaceByOutput = snapshot.currentWorkspaceByOutput || {};
          root.workspaces = snapshot.workspaces || {};
          if (snapshot.monitors)
            root.monitors = snapshot.monitors;
          root.active = true;
          // cache won: fallback watcher would only double-apply
          fallbackWatch.running = false;
        }
      }
    }
  }

  Timer {
    id: retryTimer
    interval: 2000
    onTriggered: {
      if (!root.active) {
        cacheView.reload();
        if (!root.active)
          fallbackWatch.running = Quickshell.env("XDG_CURRENT_DESKTOP") === "mango";
      }
    }
  }

  // daemon launcher — start nixtop-mango-ipc if available under mango.
  // Same source as nixtop-sway-ipc (package.nix): mango mode via explicit
  // --mango or auto-detect (no SWAYSOCK + mmsg on PATH).
  Process {
    id: daemonProc
    command: ["bash", "-c", "command -v nixtop-mango-ipc >/dev/null 2>&1 && exec nixtop-mango-ipc || command -v nixtop-sway-ipc >/dev/null 2>&1 && exec nixtop-sway-ipc --mango || exit 0"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") === "mango"
    stdout: SplitParser {
      onRead: data => console.log("[MANGO-IPC] " + data)
    }
    stderr: SplitParser {
      onRead: data => console.log("[MANGO-IPC] " + data)
    }
  }

  Component.onCompleted: {
    cacheView.reload();
  }
}
