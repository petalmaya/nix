pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.Data as Dat
import qs.Widgets as Wid
import qs.Generics as Gen

// The login UI, shown once per greeter.qml invocation (Layers/Greeter.qml's
// `primary` gating - only one monitor gets this, others just get
// wallpaper). Modeled after Containers/LockScreenSurface.qml (same
// wallpaper + blur backdrop), but auth goes through Dat.Greeter
// (greetd), not Quickshell.Services.Pam.
Item {
  id: root

  // Escape-quits, mock mode only - a real greetd session shouldn't
  // let Escape kill the greeter process at an actual login screen
  focus: Dat.Greeter.mockMode

  Keys.onEscapePressed: if (Dat.Greeter.mockMode)
    Qt.quit()

  Wid.Wallpaper {
    id: wallpaper

    // outputName deliberately unset - always the lock/greeter
    // wallpaper, same choice LockScreenSurface makes
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

  // top-left clock, oversized like a DM greeter rather than the
  // notch's small pill (Widgets/TimePill.qml)
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

  // login card - bottom-left, unlike the launcher/net panel's
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
      radius: Dat.Radius.full

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

    // password row - eye toggle flips TextInput.echoMode rather than
    // a separate reveal overlay, so cursor/selection survive it
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.72)
      radius: Dat.Radius.full

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
            layerRadius: Dat.Radius.full

            onClicked: Dat.Greeter.passwordVisible = !Dat.Greeter.passwordVisible
          }
        }
      }
    }

    // only takes up space once there's an error, so the card doesn't
    // jump around on every keystroke
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
      radius: Dat.Radius.full

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

    // click-to-cycle instead of a dropdown, keeps the card
    // keyboard-first (tab never needs to leave the two fields + button)
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
