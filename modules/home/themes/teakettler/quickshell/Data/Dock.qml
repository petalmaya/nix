pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data as Dat

// Dock backing store (see Containers/Dock.qml); pins persist to dock.json like Config.qml.
Singleton {
  id: root

  // Magnify tuning shared via Containers/Dock.qml; radius 60 so neighbors don't over-magnify.
  readonly property real magnifyRadius: 60
  readonly property real magnifyScale: 0.4

  property alias pinned: jsonData.pinnedApps

  // appId -> Toplevels; only reassigned on diff so the Repeater doesn't flicker.
  property var toplevelsByAppId: ({})

  function _sameShape(a, b) {
    const aKeys = Object.keys(a);
    const bKeys = Object.keys(b);
    if (aKeys.length != bKeys.length)
      return false;
    for (const k of aKeys) {
      if (!b[k] || a[k].length != b[k].length)
        return false;
      for (let i = 0; i < a[k].length; i++) {
        if (a[k][i] !== b[k][i])
          return false;
      }
    }
    return true;
  }

  function _rebuildToplevels() {
    const map = {};
    const byKey = {};
    const live = new Set();
    for (const t of ToplevelManager.toplevels.values) {
      const id = (t.appId ?? "").toLowerCase();
      if (!id)
        continue;
      if (!map[id])
        map[id] = [];
      map[id].push(t);
      const key = root._keyFor(t);
      byKey[key] = t;
      live.add(t);
    }
      // drop keys for closed toplevels so this doesn't grow forever
    for (const t of [...root._toplevelKeys.keys()]) {
      if (!live.has(t))
        root._toplevelKeys.delete(t);
    }
    if (!root._sameShape(map, root.toplevelsByAppId)) {
      root.toplevelsByAppId = map;
    }
    root.toplevelsByKey = byKey;
    root._syncRunningModel();
  }

  // Stable per-Toplevel keys (JS Map only); raw objects never go into the ListModel.
  property var _toplevelKeys: new Map()
  property int _nextKey: 0

  function _keyFor(t) {
    if (!root._toplevelKeys.has(t)) {
      root._toplevelKeys.set(t, "tl-" + root._nextKey++);
    }
    return root._toplevelKeys.get(t);
  }

  // Key -> live Toplevel; DockItem resolves via toplevelForKey against what's alive.
  property var toplevelsByKey: ({})

  function toplevelForKey(key) {
    return root.toplevelsByKey[key] ?? null;
  }

  // runningModel is an incrementally synced ListModel of flat {appId, key, closing} roles:
  // wholesale rebuilds segfaulted on hover, nested roles break type inference, raw Toplevels dangle.
  function _syncRunningModel() {
    const desired = [];
    for (const id in root.toplevelsByAppId) {
      if (root.isPinned(id))
        continue;
      for (const t of root.toplevelsByAppId[id]) {
        desired.push({
          "appId": id,
          "key": root._keyFor(t)
        });
      }
    }
    const desiredKeys = new Set(desired.map(d => d.key));

    for (let i = runningModel.count - 1; i >= 0; i--) {
      const row = runningModel.get(i);
      if (!desiredKeys.has(row.key) && !row.closing) {
        // still present in the model, just flagged - DockItem will
        // call confirmClosed() once it's safe to actually remove it
        runningModel.setProperty(i, "closing", true);
      }
    }

    const existingKeys = new Set();
    for (let i = 0; i < runningModel.count; i++) {
      existingKeys.add(runningModel.get(i).key);
    }
    for (const d of desired) {
      if (!existingKeys.has(d.key)) {
        runningModel.append({
          "appId": d.appId,
          "key": d.key,
          "closing": false
        });
      }
    }
  }

  // Called by DockItem after its exit animation; skips removal if the key was re-added.
  function confirmClosed(key) {
    for (let i = 0; i < runningModel.count; i++) {
      const row = runningModel.get(i);
      if (row.key == key && row.closing) {
        runningModel.remove(i);
        return;
      }
    }
  }

  function isPinned(appId) {
    const id = (appId ?? "").toLowerCase();
    return jsonData.pinnedApps.some(p => p.toLowerCase() == id);
  }

  function pin(appId) {
    if (!appId || root.isPinned(appId))
      return;
    jsonData.pinnedApps = [...jsonData.pinnedApps, appId];
    root._syncRunningModel();
  }

  function unpin(appId) {
    const id = (appId ?? "").toLowerCase();
    jsonData.pinnedApps = jsonData.pinnedApps.filter(p => p.toLowerCase() != id);
    root._syncRunningModel();
  }

  function togglePin(appId) {
    if (root.isPinned(appId)) {
      root.unpin(appId);
    } else {
      root.pin(appId);
    }
  }

  // One entry per pinned app regardless of open window count - click
  // focuses the most recent window, or launches if not running.
  readonly property var pinnedEntries: jsonData.pinnedApps.map(appId => ({
        "appId": appId
      }))

  // One row per window (not per app); pinned apps excluded to avoid duplicates (see _syncRunningModel).
  property alias runningModel: runningModel

  ListModel {
    id: runningModel
  }

  // Fuzzy DesktopEntry match (case, reverse-DNS, suffixes); falls back to a generic glyph.
  function desktopEntryFor(appId) {
    if (!appId)
      return null;
    const id = appId.toLowerCase();
    const apps = [...DesktopEntries.applications.values];
    return apps.find(e => (e.id ?? "").toLowerCase() == id) ?? apps.find(e => (e.id ?? "").toLowerCase().startsWith(id)) ?? apps.find(e => (e.id ?? "").toLowerCase().endsWith("." + id)) ?? apps.find(e => (e.name ?? "").toLowerCase() == id) ?? null;
  }

  function launchOrFocus(appId) {
    const running = root.toplevelsByAppId[appId.toLowerCase()];
    if (running && running.length > 0) {
      root.focusToplevel(running[running.length - 1]);
      return;
    }
    const entry = root.desktopEntryFor(appId);
    if (entry) {
      entry.execute();
    }
  }

  function focusToplevel(toplevel) {
    if (!toplevel)
      return;
    // Toplevel.activate() focuses the window (confirmed against niri)
    toplevel.activate();
  }

  Component.onCompleted: root._rebuildToplevels()

  // Polls (no change signal); 2000ms since only diffs reassign and the dock isn't behind a Loader.
  Timer {
    interval: 2000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: root._rebuildToplevels()
  }

  FileView {
    path: Dat.Paths.config + "/dock.json"
    watchChanges: true

    onAdapterUpdated: writeAdapter()
    onFileChanged: reload()
    onLoadFailed: err => {
      if (err == FileViewError.FileNotFound) {
        writeAdapter();
      }
    }

    JsonAdapter {
      id: jsonData

      property list<string> pinnedApps: ["foot", "firefox-esr", "org.gnome.Nautilus"]
    }
  }
}
