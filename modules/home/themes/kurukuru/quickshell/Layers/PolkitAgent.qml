pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// Single global instance (like Layers/LockScreen.qml) - a polkit request
// isn't a per-output concept, it's one system-wide conversation, so this
// mounts once in shell.qml rather than once per screen. Shows on
// Niri.focusedOutput (same "guess where the user is" helper every other
// global-trigger surface in this tree uses) so it doesn't pop up on a
// monitor nobody's looking at.
WlrLayershell {
  id: root

  readonly property bool open: Dat.Polkit.active
  property bool surfaceVisible: false

  function _targetScreen() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      const match = Quickshell.screens.find(s => s.name == Dat.Niri.focusedOutput);
      if (match)
        return match;
    }
    return Quickshell.screens[0] ?? null;
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.open
  keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukuru-polkit"
  screen: root._targetScreen()
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
      passwordField.forceActiveFocus();
    } else {
      closeLinger.restart();
    }
  }

  Timer {
    id: closeLinger

    interval: Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  // scrim - deliberately no click-off here, unlike NetPanel/Launcher:
  // dismissing a live auth request by fat-fingering a click outside the
  // card would be a much worse surprise than a launcher closing early.
  // Escape (below, on the card) still cancels explicitly.
  Rectangle {
    anchors.fill: parent
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface, 0.6)
    opacity: root.open ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
      }
    }
  }

  Rectangle {
    id: card

    anchors.centerIn: parent
    color: Dat.Colors.current.surface_container_high
    height: content.implicitHeight + 48
    opacity: root.open ? 1 : 0
    radius: 24
    scale: root.open ? 1 : 0.92
    width: 420

    Behavior on opacity {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Keys.onEscapePressed: Dat.Polkit.cancel()

    Column {
      id: content

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 24
      spacing: 14
      width: parent.width - 48

      Gen.MatIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Dat.Colors.current.primary
        font.pointSize: 24
        icon: "shield_lock"
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Dat.Colors.current.on_surface
        font.pointSize: 14
        font.weight: Font.DemiBold
        text: "Authentication required"
      }

      Text {
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: 10
        horizontalAlignment: Text.AlignHCenter
        text: Dat.Polkit.message
        width: parent.width
        wrapMode: Text.Wrap
      }

      Rectangle {
        id: fieldRect

        border.color: Dat.Polkit.failed ? Dat.Colors.current.error : (passwordField.activeFocus ? Dat.Colors.current.primary : Dat.Colors.current.outline)
        border.width: 1
        color: "transparent"
        height: 44
        radius: 12
        width: parent.width

        TextInput {
          id: passwordField

          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          clip: true
          color: Dat.Colors.current.on_surface
          echoMode: (Dat.Polkit.flow && Dat.Polkit.flow.responseVisible) ? TextInput.Normal : TextInput.Password
          enabled: Dat.Polkit.interactionAvailable
          font.pointSize: 11
          verticalAlignment: TextInput.AlignVCenter

          Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Dat.Colors.current.on_surface_variant
            font.pointSize: 11
            text: Dat.Polkit.cleanPrompt
            visible: passwordField.text.length == 0
          }

          onAccepted: Dat.Polkit.submit(passwordField.text)
          onTextChanged: if (Dat.Polkit.failed)
            Dat.Polkit.failed = false
        }
      }

      Text {
        color: Dat.Colors.current.error
        font.pointSize: 9
        text: "Authentication failed, try again"
        visible: Dat.Polkit.failed
      }

      Row {
        anchors.right: parent.right
        spacing: 8

        Rectangle {
          color: "transparent"
          height: 32
          radius: 16
          width: 72

          Text {
            anchors.centerIn: parent
            color: Dat.Colors.current.primary
            font.pointSize: 10
            text: "Cancel"
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 16

            onClicked: Dat.Polkit.cancel()
          }
        }

        Rectangle {
          color: "transparent"
          height: 32
          radius: 16
          width: 72

          Text {
            anchors.centerIn: parent
            color: Dat.Polkit.interactionAvailable ? Dat.Colors.current.primary : Dat.Colors.current.on_surface_variant
            font.pointSize: 10
            text: "OK"
          }

          Gen.MouseArea {
            enabled: Dat.Polkit.interactionAvailable
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 16

            onClicked: Dat.Polkit.submit(passwordField.text)
          }
        }
      }
    }

    Connections {
      function onInteractionAvailableChanged() {
        if (Dat.Polkit.interactionAvailable) {
          passwordField.text = "";
          passwordField.forceActiveFocus();
        }
      }

      target: Dat.Polkit
    }
  }
}
