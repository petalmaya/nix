pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.UPower

import qs.Data as Dat
import qs.Generics as Gen

// Content for Layers/QuickOptions.qml - grid of one-tap toggles.
// Self-contained, same pattern as Generics/NetworkPanel.qml.
//
// Wi-Fi used to be its own popover (Layers/NetPanel.qml) - folded in
// here Android-quick-settings style: the Wi-Fi tile is a fast toggle,
// "Networks & devices" expands the full network + Bluetooth list
// (Generics/NetworkPanel.qml) in place. Layers/NetPanel.qml is kept
// around unregistered rather than deleted, see the note at its top.
ColumnLayout {
  id: root

  property string outputName: ""
  readonly property var btAdapter: Bluetooth.defaultAdapter
  property bool networkExpanded: false

  spacing: 10

  // flip the same per-output flag NetPanel.qml used to own, so
  // Data/Network.qml's background-poll throttle keeps working. Also
  // stops any bluetooth scan once nobody's looking, like NetPanel.close().
  onNetworkExpandedChanged: {
    Dat.Globals.setNetworkPanelOpen(root.outputName, root.networkExpanded);
    if (!root.networkExpanded && (Bluetooth.defaultAdapter?.discovering ?? false)) {
      Bluetooth.defaultAdapter.discovering = false;
    }
  }

  Text {
    Layout.fillWidth: true
    color: Dat.Colors.current.on_surface_variant
    font.pointSize: 10
    font.weight: Font.DemiBold
    text: "QUICK OPTIONS"
  }

  GridLayout {
    Layout.fillWidth: true
    columnSpacing: 8
    columns: 2
    rowSpacing: 8

    Gen.QuickOptionTile {
      Layout.fillWidth: true
      active: Dat.Network.wifiEnabled
      icon: Dat.Network.wifiEnabled ? "wifi" : "wifi_off"
      label: "Wi-Fi"

      onClicked: Dat.Network.toggleWifi()
    }

    Gen.QuickOptionTile {
      Layout.fillWidth: true
      active: root.btAdapter?.enabled ?? false
      icon: (root.btAdapter?.enabled ?? false) ? "bluetooth" : "bluetooth_disabled"
      label: "Bluetooth"

      onClicked: {
        if (root.btAdapter)
          root.btAdapter.enabled = !root.btAdapter.enabled;
      }
    }

    Gen.QuickOptionTile {
      Layout.fillWidth: true
      active: Dat.SessionActions.idleInhibited
      icon: Dat.SessionActions.idleInhibited ? "visibility" : "visibility_off"
      label: "Keep Awake"

      onClicked: Dat.SessionActions.toggleIdle()
    }

    Gen.QuickOptionTile {
      Layout.fillWidth: true
      // 0=balanced, 1=performance, 2=power saver - same raw values
      // PowerTab.qml's slider uses
      active: PowerProfiles.profile != 0
      icon: switch (PowerProfiles.profile) {
      case 1:
        "bolt";
        break;
      case 2:
        "battery_saver";
        break;
      default:
        "balance";
        break;
      }
      label: switch (PowerProfiles.profile) {
      case 1:
        "Performance";
        break;
      case 2:
        "Power Saver";
        break;
      default:
        "Balanced";
        break;
      }

      // no dedicated "cycle profile" API - step through 0/1/2 in order
      onClicked: PowerProfiles.profile = (PowerProfiles.profile + 1) % 3
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: 4
    color: Dat.Colors.current.outline_variant
    height: 1
    opacity: 0.4
  }

  // "Networks & devices" expander, Android quick-settings style
  Item {
    Layout.fillWidth: true
    implicitHeight: expandRow.implicitHeight

    // Gen.MouseArea fills its parent, and a RowLayout child can't take
    // one directly (anchors-on-layout-managed-item warning) - the
    // plain Item wrapper gives it a non-layout parent to fill instead.
    RowLayout {
      id: expandRow

      anchors.fill: parent
      spacing: 6

      Gen.MatIcon {
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: 14
        icon: "wifi_tethering"
      }

      Text {
        Layout.fillWidth: true
        color: Dat.Colors.current.on_surface
        font.pointSize: 10
        text: "Networks & devices"
      }

      Gen.MatIcon {
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: 14
        icon: root.networkExpanded ? "expand_less" : "expand_more"

        Behavior on rotation {
          NumberAnimation {
            duration: Dat.MaterialEasing.standardTime
          }
        }
      }
    }

    Gen.MouseArea {
      layerColor: Dat.Colors.current.on_surface
      layerRadius: 12

      onClicked: root.networkExpanded = !root.networkExpanded
    }
  }

  // Loader, not just visible:false, so NetworkPanel.qml's wifi/bluetooth
  // scanning only runs while this section is actually open
  Loader {
    Layout.fillWidth: true
    active: root.networkExpanded
    opacity: root.networkExpanded ? 1 : 0
    sourceComponent: Gen.NetworkPanel {
    }
    visible: active

    Behavior on opacity {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: 4
    color: Dat.Colors.current.outline_variant
    height: 1
    opacity: 0.4
  }

  RowLayout {
    id: sessionRow

    property bool actionSent: false

    Layout.fillWidth: true
    spacing: 8

    Gen.MatIcon {
      color: Dat.Colors.current.on_surface_variant
      font.pointSize: 14
      icon: "power_settings_new"
    }

    Text {
      Layout.fillWidth: true
      color: Dat.Colors.current.on_surface
      font.pointSize: 11
      text: "Session"
    }

    // debounces the whole row - poweroff/reboot double-firing isn't
    // as dangerous as double-locking (see LockScreen.qml's own guard),
    // but none of these three should fire twice either
    Timer {
      id: actionCooldown

      interval: 1200

      onTriggered: sessionRow.actionSent = false
    }

    Repeater {
      model: [
        {
          icon: "lock",
          // in-process via Data/Globals.qml's lockRequested signal -
          // see its comment for why the old execDetached call did nothing
          action: () => Dat.Globals.requestLock()
        },
        {
          icon: "restart_alt",
          action: () => Dat.SessionActions.reboot()
        },
        {
          icon: "power_settings_new",
          action: () => Dat.SessionActions.poweroff()
        }
      ]

      Rectangle {
        id: sessionBtn

        required property var modelData

        color: Dat.Colors.current.surface_container
        implicitHeight: 26
        implicitWidth: 26
        radius: Dat.Radius.full

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Colors.current.on_surface
          font.pointSize: 12
          icon: sessionBtn.modelData.icon
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 13

          onClicked: {
            if (sessionRow.actionSent)
              return;
            sessionRow.actionSent = true;
            actionCooldown.restart();
            sessionBtn.modelData.action();
          }
        }
      }
    }
  }
}
