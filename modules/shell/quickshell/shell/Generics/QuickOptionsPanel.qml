pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.UPower

import qs.Data as Dat
import qs.Generics as Gen

ColumnLayout {
  id: root

  property string outputName: ""
  readonly property var btAdapter: Bluetooth.defaultAdapter
  property bool networkExpanded: false

  spacing: 10

  // Mirrors NetPanel open flag for Data/Network.qml poll throttle; stops Bluetooth scan on close.
  onNetworkExpandedChanged: {
    Dat.Globals.setNetworkPanelOpen(root.outputName, root.networkExpanded);
    if (!root.networkExpanded && (Bluetooth.defaultAdapter?.discovering ?? false)) {
      Bluetooth.defaultAdapter.discovering = false;
    }
  }

  Text {
    Layout.fillWidth: true
    color: Dat.Colors.current.on_surface_variant
    font.pointSize: Dat.Type.labelSmall
    font.weight: Dat.Type.weightBold
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
      // Same raw 0/1/2 values PowerTab's slider uses.
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

  Item {
    Layout.fillWidth: true
    implicitHeight: expandRow.implicitHeight

    // Item wrapper gives MouseArea a non-layout parent to fill.
    RowLayout {
      id: expandRow

      anchors.fill: parent
      spacing: 6

      Gen.MatIcon {
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: Dat.Type.titleSmall
        icon: "wifi_tethering"
      }

      Text {
        Layout.fillWidth: true
        color: Dat.Colors.current.on_surface
        font.pointSize: Dat.Type.labelSmall
        text: "Networks & devices"
      }

      Gen.MatIcon {
        color: Dat.Colors.current.on_surface_variant
        font.pointSize: Dat.Type.titleSmall
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
      layerRadius: Dat.Radius.md

      onClicked: root.networkExpanded = !root.networkExpanded
    }
  }

  // Loader gates NetworkPanel scanning to while this section is open.
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
      font.pointSize: Dat.Type.titleSmall
      icon: "power_settings_new"
    }

    Text {
      Layout.fillWidth: true
      color: Dat.Colors.current.on_surface
      font.pointSize: Dat.Type.labelSmall
      text: "Session"
    }

    Timer {
      id: actionCooldown

      interval: 1200

      onTriggered: sessionRow.actionSent = false
    }

    Repeater {
      model: [
        {
          icon: "lock",
          // Locks in-process; shelling out fails when qs is missing from PATH.
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
          font.pointSize: Dat.Type.labelMedium
          icon: sessionBtn.modelData.icon
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: Dat.Radius.md

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
