pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data as Dat

// Backing store for the dock (Containers/Dock.qml). Persists pinned
// desktop-entry ids to dock.json (same FileView/JsonAdapter pattern as
// Config.qml) and merges them at runtime with what's actually running.
Singleton {
  id: root

  property alias pinned: jsonData.pinnedApps

  // appId -> list of Toplevel, from ToplevelManager.toplevels. Only
  // reassigned when the set actually changes (see _sameShape) -
  // reassigning every poll regardless of content made the Repeater see
  // a "new" model every second and destroy/recreate delegates,
  // causing the hover flicker at the dock's edges.
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

  // Stable string key per live Toplevel, JS-side only (plain Map),
  // never written into runningModel/ListModel - see _syncRunningModel
  // for why the raw Toplevel object must never go into the ListModel.
  property var _toplevelKeys: new Map()
  property int _nextKey: 0

  function _keyFor(t) {
    if (!root._toplevelKeys.has(t)) {
      root._toplevelKeys.set(t, "tl-" + root._nextKey++);
    }
    return root._toplevelKeys.get(t);
  }

  // key -> live Toplevel, rebuilt every poll. DockItem looks its
  // Toplevel up through toplevelForKey rather than holding one
  // directly, so it always resolves against what's alive right now.
  property var toplevelsByKey: ({})

  function toplevelForKey(key) {
    return root.toplevelsByKey[key] ?? null;
  }

  // This used to be a plain array rebuilt wholesale on every
  // toplevelsByAppId change, which made the Repeater destroy and
  // recreate every DockItem on any window open/close - including ones
  // nothing happened to, which segfaulted if the mouse was mid-hover
  // over one at that instant. runningModel is a real ListModel kept
  // in sync incrementally instead, touching only the rows that
  // actually changed.
  //
  // Rows hold appId + a string key only, never the live Toplevel
  // object - ListModel's "var" roles don't track QObject lifetime, so
  // a closed window's row would hold a dangling pointer.
  //
  // Closed windows are NOT removed synchronously here anymore. A row
  // whose toplevel disappeared gets marked `closing: true` instead;
  // DockItem is responsible for disabling its own MouseArea hover and
  // fading out *before* calling confirmClosed() to actually drop the
  // row. Removing the row (and thus destroying the delegate/MouseArea)
  // while it could still be the hovered item is what was segfaulting
  // in QQuickDeliveryAgentPrivate::clearHover - Qt walks its hover
  // item on the next leave/move event, and by then the delegate was
  // already gone.
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
      const row = runningModel.get(i).modelData;
      if (!desiredKeys.has(row.key) && !row.closing) {
        // still present in the model, just flagged - DockItem will
        // call confirmClosed() once it's safe to actually remove it
        runningModel.setProperty(i, "modelData", Object.assign({}, row, {
          "closing": true
        }));
      }
    }

    const existingKeys = new Set();
    for (let i = 0; i < runningModel.count; i++) {
      existingKeys.add(runningModel.get(i).modelData.key);
    }
    for (const d of desired) {
      if (!existingKeys.has(d.key)) {
        runningModel.append({
          "modelData": Object.assign({
            "closing": false
          }, d)
        });
      }
    }
  }

  // Called by DockItem once it has disabled hover and finished its
  // exit animation for a row that's no longer backed by a live
  // toplevel. Only actually removes the row if it's still marked
  // closing (it may have already been re-added under the same key by
  // a later _syncRunningModel, e.g. a very quick close+relaunch).
  function confirmClosed(key) {
    for (let i = 0; i < runningModel.count; i++) {
      const row = runningModel.get(i).modelData;
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

  // One entry per *window*, not per app - two Firefox windows show as
  // two icons. Pinned apps are excluded here even while running, to
  // avoid duplicating their pinnedEntries icon.
  //
  // Real ListModel, not a plain array - see _syncRunningModel above.
  property alias runningModel: runningModel

  ListModel {
    id: runningModel
  }

  // finds a launchable DesktopEntry for a dock appId - exact id match
  // first, then looser fallbacks, since the compositor's appId doesn't
  // always match the .desktop filename exactly (case, reverse-dns
  // prefix, -esr suffixes). No match falls back to DockItem.qml's
  // generic "apps" glyph rather than erroring.
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

  // Polls rather than hooking a ToplevelManager change signal - cheap
  // since _rebuildToplevels only reassigns on an actual diff.
  Timer {
    interval: 1000
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
