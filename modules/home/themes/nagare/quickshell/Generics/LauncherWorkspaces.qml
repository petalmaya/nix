pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher.mode == "workspaces" - numbered grid, one
// tile per workspace on the current output, click or Enter jumps
// there. Just numbered tiles, not live thumbnails - that'd need
// wlr-screencopy per workspace, a real chunk of new plumbing, flagged
// as a known gap in handoff.md.
//
// Works against whichever backend is active - Niri.workspaces and
// MangoWC.workspaces are both keyed maps of niri-shaped workspace objects.
Item {
  id: root

  signal requestFocus

  readonly property string outputName: Dat.Launcher.outputName
  readonly property bool backendActive: Dat.Niri.active || Dat.MangoWC.active
  readonly property var backend: Dat.Niri.active ? Dat.Niri : Dat.MangoWC

  // just "how many tiles do we know about for this output", not a
  // hardcoded grid size
  readonly property var workspacesForOutput: {
    if (!root.backendActive)
      return [];

    const list = [];
    for (const id in root.backend.workspaces) {
      const w = root.backend.workspaces[id];
      if (w.output == root.outputName)
        list.push(w);
    }
    list.sort((a, b) => a.idx - b.idx);
    return list;
  }

  readonly property int currentIdx: root.backendActive ? root.backend.workspaceFor(root.outputName) : 0
  // keyboard cursor into workspacesForOutput, separate from currentIdx
  // so arrowing doesn't switch anything until Enter - same "browse,
  // then commit" shape as LauncherApps.qml's list.currentIndex
  property int selectedIndex: -1
  readonly property int columns: grid.columns

  function switchTo(idx) {
    root.backend.setCurrentTag(idx, root.outputName);
    Dat.Launcher.hide();
  }

  function switchToSelected() {
    const w = root.workspacesForOutput[root.selectedIndex];
    if (w)
      root.switchTo(w.idx);
  }

  // lands the cursor on the current workspace, so the first arrow
  // press moves relative to "where you are"
  function _resetSelection() {
    const idx = root.workspacesForOutput.findIndex(w => w.idx == root.currentIdx);
    root.selectedIndex = idx >= 0 ? idx : (root.workspacesForOutput.length > 0 ? 0 : -1);
  }

  implicitHeight: root.backendActive ? grid.implicitHeight : fallback.implicitHeight

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
    text: "Workspace switching needs niri or mango"
    visible: !root.backendActive
    width: parent.width
    wrapMode: Text.Wrap
  }

  GridLayout {
    id: grid

    columns: 5
    columnSpacing: 8
    rowSpacing: 8
    visible: root.backendActive
    width: parent.width

    Repeater {
      model: root.workspacesForOutput

      Rectangle {
        id: tile

        required property var modelData
        required property int index

        readonly property bool current: tile.modelData.idx == root.currentIdx
        readonly property bool selected: tile.index == root.selectedIndex
        // mango-only field - always undefined (falsy) on niri, so this
        // just never lights up there
        readonly property bool urgent: !!tile.modelData.is_urgent

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        border.color: tile.urgent ? Dat.Colors.current.error : (tile.current ? Dat.Colors.current.primary : (tile.selected ? Dat.Colors.current.outline : "transparent"))
        border.width: 2
        color: tile.current ? Dat.Colors.current.primary_container : (tile.selected ? Dat.Colors.current.surface_container_high : Dat.Colors.current.surface_container)
        radius: Dat.Radius.lgSm

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
