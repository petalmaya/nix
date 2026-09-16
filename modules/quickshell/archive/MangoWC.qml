pragma Singleton
import Quickshell
import Quickshell.Io

// Mango IPC via `mmsg watch all-monitors` (full snapshot per change); mirrors Niri.qml,
// first active tag reads as current.
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
    // Skipped under niri (no mmsg socket); avoids forking bash for a doomed process.
    command: ["bash", "-c", "command -v mmsg >/dev/null 2>&1 && exec mmsg watch all-monitors || exit 0"]
    running: Quickshell.env("XDG_CURRENT_DESKTOP") === "mango"

    stdout: SplitParser {
      onRead: line => {
        if (!line || line.length === 0)
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
}
