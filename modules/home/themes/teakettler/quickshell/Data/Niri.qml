pragma Singleton
import Quickshell
import Quickshell.Io

// Niri workspaces via `niri msg -j event-stream`; per-output for one bar per monitor.
// TODO: expose urgency and other workspace values.
Singleton {
  id: root

  // true once we've actually heard from a running niri instance
  property bool active: false
  // idx (1-based) of the globally focused workspace, kept for single
  // monitor / back-compat callers that don't care which output
  property int currentWorkspace: 1
  // Focused output for defaulting keybind/IPC calls with no output arg.
  property string focusedOutput: ""
  // output name -> idx of that output's currently visible workspace
  property var currentWorkspaceByOutput: ({})
  // id -> workspace object, as last reported by niri
  property var workspaces: ({})

  function _applyWorkspace(w) {
    if (!w || !w.output)
      return;

    const updated = Object.assign({}, root.currentWorkspaceByOutput);
    updated[w.output] = w.idx;
    root.currentWorkspaceByOutput = updated;

    if (w.is_focused) {
      root.currentWorkspace = w.idx;
      root.focusedOutput = w.output;
    }
  }

  // workspace idx currently shown on the given output, falling back to
  // the globally focused idx if we don't have per-output data yet
  function workspaceFor(outputName) {
    if (outputName && root.currentWorkspaceByOutput[outputName] !== undefined) {
      return root.currentWorkspaceByOutput[outputName];
    }
    return root.currentWorkspace;
  }

  function _escape(str) {
    return `'${String(str).replace(/'/g, `'\\''`)}'`;
  }

  // Focuses the monitor first; niri resolves workspace indices relative to the focused monitor.
  function setCurrentTag(idx, outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace ${idx}`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", `${idx}`]);
    }
  }

  function focusNext(outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace-down`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }
  }

  function focusPrev(outputName) {
    if (outputName) {
      Quickshell.execDetached(["bash", "-c", `niri msg action focus-monitor ${root._escape(outputName)} && niri msg action focus-workspace-up`]);
    } else {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }
  }

  Process {
    // Skipped under mango (no niri binary); avoids spawning a doomed process.
    command: ["niri", "msg", "-j", "event-stream"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") !== "mango"

    stdout: SplitParser {
      onRead: line => {
        if (!line || line.length === 0)
          return;

        let event;
        try {
          event = JSON.parse(line);
        } catch (e) {
          return;
        }

        root.active = true;

        if (event.WorkspacesChanged) {
          const ws = {};
          for (const w of event.WorkspacesChanged.workspaces) {
            ws[w.id] = w;
            if (w.is_active) {
              root._applyWorkspace(w);
            }
          }
          root.workspaces = ws;
        } else if (event.WorkspaceActivated) {
          const activated = event.WorkspaceActivated;
          const w = root.workspaces[activated.id];
          if (w) {
            w.is_active = true;
            // is_focused isn't implied by is_active; only set it when the event reports focus.
            w.is_focused = !!activated.focused;
            root._applyWorkspace(w);
          }
        }
      }
    }
  }
}
