pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher.mode == "workspaces" - a numbered grid, one
// tile per workspace on the output the launcher is currently showing on,
// current one highlighted, click (or Enter on the selected tile) jumps
// there and closes the launcher. Deliberately just numbered tiles, not
// live per-workspace window thumbnails - that'd need wlr-screencopy
// frames composited per workspace, which is a real chunk of new plumbing
// (Data/*.qml singleton + scripts/ capture helper) rather than a
// same-shape extension of what LauncherApps.qml already does. Flagged as
// a known gap in handoff.md rather than guessed at here.
//
// niri-only for now, same as the rest of Data/Niri.qml's per-output
// workspace tracking - Data/MangoWC.qml only exposes a single
// `currentWorkspace` tag string with no list of what else exists, so
// there's nothing to build a grid out of there yet (see handoff.md's
// mangowc parity notes).
Item {
  id: root

  signal requestFocus

  readonly property string outputName: Dat.Launcher.outputName

  // niri workspace idx are 1-based and dense per-output; this is just
  // "how many tiles do we know about for this output", not a hardcoded
  // grid size
  readonly property var workspacesForOutput: {
    const list = [];
    for (const id in Dat.Niri.workspaces) {
      const w = Dat.Niri.workspaces[id];
      if (w.output == root.outputName)
        list.push(w);
    }
    list.sort((a, b) => a.idx - b.idx);
    return list;
  }

  readonly property int currentIdx: Dat.Niri.workspaceFor(root.outputName)
  // keyboard cursor into workspacesForOutput - separate from currentIdx
  // (which workspace niri is actually on) so arrowing around doesn't
  // switch anything until Enter, same "browse, then commit" shape as
  // LauncherApps.qml's list.currentIndex
  property int selectedIndex: -1
  readonly property int columns: grid.columns

  function switchTo(idx) {
    Dat.Niri.setCurrentTag(idx, root.outputName);
    Dat.Launcher.hide();
  }

  function switchToSelected() {
    const w = root.workspacesForOutput[root.selectedIndex];
    if (w)
      root.switchTo(w.idx);
  }

  // lands the cursor on whatever workspace is actually current, so the
  // first arrow press moves relative to "where you are" rather than
  // jumping from some arbitrary corner
  function _resetSelection() {
    const idx = root.workspacesForOutput.findIndex(w => w.idx == root.currentIdx);
    root.selectedIndex = idx >= 0 ? idx : (root.workspacesForOutput.length > 0 ? 0 : -1);
  }

  implicitHeight: Dat.Niri.active ? grid.implicitHeight : fallback.implicitHeight

  Keys.onLeftPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
  Keys.onRightPressed: root.selectedIndex = Math.min(root.workspacesForOutput.length - 1, root.selectedIndex + 1)
  Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - root.columns)
  Keys.onDownPressed: root.selectedIndex = Math.min(root.workspacesForOutput.length - 1, root.selectedIndex + root.columns)
  Keys.onReturnPressed: root.switchToSelected()
  Keys.onEnterPressed: root.switchToSelected()

  onWorkspacesForOutputChanged: {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.workspacesForOutput.length)
      root._resetSelection();
  }

  Text {
    id: fallback

    color: Dat.Colors.current.on_surface_variant
    font.pointSize: 10
    horizontalAlignment: Text.AlignHCenter
    text: "Workspace switching needs niri"
    visible: !Dat.Niri.active
    width: parent.width
    wrapMode: Text.Wrap
  }

  GridLayout {
    id: grid

    columns: 5
    columnSpacing: 8
    rowSpacing: 8
    visible: Dat.Niri.active
    width: parent.width

    Repeater {
      model: root.workspacesForOutput

      Rectangle {
        id: tile

        required property var modelData
        required property int index

        readonly property bool current: tile.modelData.idx == root.currentIdx
        readonly property bool selected: tile.index == root.selectedIndex

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        border.color: tile.current ? Dat.Colors.current.primary : (tile.selected ? Dat.Colors.current.outline : "transparent")
        border.width: 2
        color: tile.current ? Dat.Colors.current.primary_container : (tile.selected ? Dat.Colors.current.surface_container_high : Dat.Colors.current.surface_container)
        radius: 14

        Text {
          anchors.centerIn: parent
          color: tile.current ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
          font.pointSize: 14
          text: tile.modelData.name || `${tile.modelData.idx}`
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 14

          onClicked: root.switchTo(tile.modelData.idx)
          onContainsMouseChanged: {
            if (containsMouse)
              root.selectedIndex = tile.index;
          }
        }
      }
    }
  }

  onRequestFocus: {
    root._resetSelection();
    root.forceActiveFocus();
  }

  Component.onCompleted: root._resetSelection()
}
