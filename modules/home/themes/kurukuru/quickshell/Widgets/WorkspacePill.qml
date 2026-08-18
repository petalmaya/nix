import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

Rectangle {
  id: root

  property string outputName: ""

  clip: true
  color: Dat.Colors.current.primary_container
  // radius intentionally height/2, not Dat.Radius.full - implicitWidth is
  // animated (see Behavior below) and a radius as large as `full` has to
  // get clamped down to size every frame while width is mid-animation,
  // which visibly loses the clamp for a frame or two (square corners for
  // ~250ms when switching workspaces). height is fixed here, so height/2
  // is always exactly the right capsule radius with nothing to clamp.
  height: 20
  implicitWidth: workRow.width + 8
  radius: height / 2

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Dat.MaterialEasing.standardDecelTime
      easing.bezierCurve: Dat.MaterialEasing.standardDecel
    }
  }

  RowLayout {
    id: workRow

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.top: parent.top
    spacing: 5

    Rectangle {
      color: Dat.Colors.current.primary
      implicitHeight: 20
      implicitWidth: 20
      radius: Dat.Radius.full

      Text {
        id: workspaceNumText

        anchors.centerIn: parent
        color: Dat.Colors.current.on_primary
        font.family: "Rubik"
        font.pointSize: 10
        font.weight: Font.Medium
        text: Dat.MangoWC.active ? Dat.MangoWC.currentWorkspace : Dat.Niri.workspaceFor(root.outputName)
      }
    }

    Text {
      id: windowNameText

      readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

      Layout.maximumWidth: 100
      color: Dat.Colors.current.on_primary_container
      elide: Text.ElideRight
      font.capitalization: Font.Capitalize
      font.family: "Rubik"
      font.letterSpacing: 0.1
      font.pointSize: 11
      font.weight: Font.Medium
      text: Dat.Globals.actWinName
    }
  }

  Gen.MouseArea {
    layerColor: Dat.Colors.current.on_primary_container
    layerRadius: 20

    onClicked: {
      if (Dat.Globals.notchState(root.outputName) == "FULLY_EXPANDED" && Dat.Globals.swipeIndex(root.outputName) == 2) {
        Dat.Globals.setNotchState(root.outputName, "EXPANDED");
      } else {
        Dat.Globals.setNotchState(root.outputName, "FULLY_EXPANDED");
        Dat.Globals.setSwipeIndex(root.outputName, 2);
      }
    }
    onWheel: event => {
      if (!Dat.Niri.active) {
        return;
      }
      if (event.angleDelta.y > 0) {
        Dat.Niri.focusPrev(root.outputName);
      } else {
        Dat.Niri.focusNext(root.outputName);
      }
    }
  }
}
