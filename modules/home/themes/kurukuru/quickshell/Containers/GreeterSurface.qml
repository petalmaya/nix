pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.Data as Dat
import qs.Widgets as Wid
import qs.Generics as Gen

// The actual login UI, shown once per greeter.qml invocation (see
// Layers/Greeter.qml's `primary` gating - only one monitor gets this,
// the rest just get wallpaper, same idea as most DMs' multi-monitor
// behavior). Deliberately modeled after Containers/LockScreenSurface.qml
// (same wallpaper + blur backdrop) since it's the closest existing
// analog in this tree, but there's no PAM/WlSessionLock here - auth goes
// through Dat.Greeter (greetd), not Quickshell.Services.Pam.
Item {
  id: root

  // Second way out of `scripts/test-greeter.sh`, on top of the
  // OnDemand-not-Exclusive fix in Layers/Greeter.qml - only active in
  // mock mode. A real greetd session deliberately does NOT get an
  // Escape-quits shortcut (that would just be a way to kill the greeter
  // process at an actual login screen, not something to offer there).
  focus: Dat.Greeter.mockMode

  Keys.onEscapePressed: if (Dat.Greeter.mockMode)
    Qt.quit()

  Wid.Wallpaper {
    id: wallpaper

    // same "always the lock/greeter wallpaper, not any per-output
    // desktop one" choice LockScreenSurface makes - outputName
    // deliberately left unset
    anchors.fill: parent

    layer.enabled: true
    layer.effect: MultiEffect {
      autoPaddingEnabled: false
      blur: 0.55
      blurEnabled: true
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Dat.Colors.withAlpha(Dat.Colors.current.background, 0.25)
  }

  // top-left clock, chunky/oversized like a DM greeter rather than the
  // notch's small pill treatment (Widgets/TimePill.qml) - this is a
  // full-screen surface with room to spare, and it's the first thing
  // meant to be readable from across the room
  ColumnLayout {
    anchors.left: parent.left
    anchors.leftMargin: 48
    anchors.top: parent.top
    anchors.topMargin: 40
    spacing: 0

    Text {
      color: Dat.Colors.current.on_background
      font.bold: true
      font.pointSize: 52
      text: Qt.formatDateTime(Dat.Clock.date, "h:mm")
    }

    Text {
      color: Dat.Colors.current.on_background
      font.pointSize: 16
      opacity: 0.8
      text: Qt.formatDateTime(Dat.Clock.date, "dddd d MMMM")
    }
  }

  // the login card itself - bottom-left, matching the reference SDDM
  // layout in the handoff request rather than the launcher/net panel's
  // centered/top-right placement, since a greeter has no "current
  // context" to anchor near
  ColumnLayout {
    id: card

    anchors.bottom: parent.bottom
    anchors.bottomMargin: 64
    anchors.left: parent.left
    anchors.leftMargin: 48
    spacing: 10
    width: 340

    // username row - icon + editable field, focused first
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.72)
      radius: 22

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface
          icon: "person"
        }

        TextInput {
          id: userField

          Layout.fillWidth: true
          color: Dat.Colors.current.on_surface
          font.pointSize: 12
          selectByMouse: true
          text: Dat.Greeter.username
          verticalAlignment: TextInput.AlignVCenter

          Keys.onReturnPressed: passField.forceActiveFocus()
          Keys.onEnterPressed: passField.forceActiveFocus()
          onTextChanged: Dat.Greeter.username = userField.text

          Component.onCompleted: userField.forceActiveFocus()
        }
      }
    }

    // password row - same shape, plus an eye toggle that flips
    // TextInput.echoMode rather than a separate "reveal" overlay, so
    // cursor position/selection survive the toggle
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.72)
      radius: 22

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface
          icon: "lock"
        }

        TextInput {
          id: passField

          Layout.fillWidth: true
          color: Dat.Colors.current.on_surface
          echoMode: Dat.Greeter.passwordVisible ? TextInput.Normal : TextInput.Password
          font.pointSize: 12
          selectByMouse: true
          text: Dat.Greeter.password
          verticalAlignment: TextInput.AlignVCenter

          Keys.onReturnPressed: Dat.Greeter.submit()
          Keys.onEnterPressed: Dat.Greeter.submit()
          onTextChanged: Dat.Greeter.password = passField.text
        }

        Gen.MatIcon {
          id: eyeIcon

          color: Dat.Colors.current.on_surface
          icon: Dat.Greeter.passwordVisible ? "visibility_off" : "visibility"

          Gen.MouseArea {
            layerColor: eyeIcon.color
            layerRadius: 14

            onClicked: Dat.Greeter.passwordVisible = !Dat.Greeter.passwordVisible
          }
        }
      }
    }

    // inline error, only takes up space once there's something to say -
    // avoids the card jumping around on every keystroke like it would if
    // this were always-visible-but-empty
    Text {
      Layout.fillWidth: true
      Layout.leftMargin: 14
      color: Dat.Colors.current.error
      font.pointSize: 10
      text: Dat.Greeter.errorMessage
      visible: Dat.Greeter.errorMessage.length > 0
      wrapMode: Text.WordWrap
    }

    Rectangle {
      id: loginButton

      Layout.fillWidth: true
      Layout.preferredHeight: 40
      Layout.topMargin: 4
      color: Dat.Colors.current.primary
      opacity: Dat.Greeter.busy ? 0.6 : 1
      radius: 20

      Text {
        anchors.centerIn: parent
        color: Dat.Colors.current.on_primary
        font.bold: true
        font.pointSize: 12
        text: Dat.Greeter.busy ? "Logging in…" : "Login"
      }

      Gen.MouseArea {
        enabled: !Dat.Greeter.busy
        layerColor: Dat.Colors.current.on_primary

        onClicked: Dat.Greeter.submit()
      }
    }

    // session picker - click to cycle, same "tap to cycle" interaction
    // as the reference screenshot's bottom-left "Session (Niri)" label,
    // rather than a dropdown (keeps this whole card keyboard-first: tab
    // order never needs to leave the two text fields + button)
    Text {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 6
      color: Dat.Colors.current.on_background
      font.pointSize: 10
      opacity: 0.85
      text: "Session (" + (Dat.Greeter.selectedSession?.name ?? "none found") + ")"

      Gen.MouseArea {
        anchors.margins: -6
        layerRadius: 8

        onClicked: Dat.Greeter.cycleSession()
      }
    }
  }
}
