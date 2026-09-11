pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher "apps" mode; owns selection/filtering for Layers/Launcher.qml Loader.
Item {
  id: root

  // pulses when the panel wants the search field focused/refocused
  // (e.g. right after the launcher opens)
  signal requestFocus

  function launchSelected() {
    const item = filtered[list.currentIndex];
    if (!item)
      return;
    item.entry.execute();
    Dat.Launcher.hide();
  }

  // Precomputed lowercased search blobs; avoids re-filtering cost per keystroke.
  readonly property var allApps: {
    const apps = [...DesktopEntries.applications.values].filter(e => e.name && !e.noDisplay);
    apps.sort((a, b) => a.name.localeCompare(b.name));
    return apps.map(e => ({
          "entry": e,
          "search": [e.name, e.comment, ...(e.keywords ?? []), e.genericName].filter(Boolean).join(" ").toLowerCase()
        }));
  }

  // filtered still holds {entry, search} wrappers, not raw
  // DesktopEntry objects - the delegate below reads modelData.entry.
  readonly property var filtered: {
    const q = Dat.Launcher.query.trim().toLowerCase();
    if (q == "")
      return root.allApps;

    return root.allApps.filter(a => a.search.includes(q));
  }

  implicitHeight: col.implicitHeight

  onFilteredChanged: list.currentIndex = root.filtered.length > 0 ? 0 : -1

  ColumnLayout {
    id: col

    anchors.fill: parent
    spacing: 8

    Rectangle {
      id: resultsBox

      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(list.contentHeight, 5 * 56) + (list.contentHeight > 0 ? 8 : 0)
      clip: true
      color: Dat.Colors.current.surface_container
      radius: Dat.Radius.lg
      visible: list.contentHeight > 0

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: Dat.MaterialEasing.standardTime
          easing.bezierCurve: Dat.MaterialEasing.standard
        }
      }

      ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 4
        boundsBehavior: Flickable.StopAtBounds
        // Warm off-screen icons so small scrolls don't re-request pixmaps.
        cacheBuffer: 300
        clip: true
        currentIndex: root.filtered.length > 0 ? 0 : -1
        model: root.filtered
        // Recycles delegates; model is a fresh array per keystroke so this avoids rebuilds.
        reuseItems: true
        spacing: 2

        delegate: Rectangle {
          id: entryDelegate

          required property var modelData
          required property int index

          color: (list.currentIndex == index) ? Dat.Colors.current.surface_container_highest : "transparent"
          height: 52
          radius: Dat.Radius.md
          width: list.width

          // Disable hover while pooled; delivering hover mid-recycle segfaults (see Data/Dock.qml).
          ListView.onPooled: hoverArea.hoverEnabled = false
          ListView.onReused: hoverArea.hoverEnabled = true

          // Selection marker is a primary pill; background wash collapses on monochrome wallpapers.
          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: Dat.Colors.current.primary
            height: parent.height * 0.5
            opacity: (list.currentIndex == entryDelegate.index) ? 1 : 0
            radius: Dat.Radius.full
            width: 3

            Behavior on opacity {
              NumberAnimation {
                duration: Dat.MaterialEasing.standardTime
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 12

            IconImage {
              id: appIcon

              Layout.preferredHeight: 32
              Layout.preferredWidth: 32
              // Async decode; recycled delegates load different icons without blocking a frame.
              asynchronous: true
              // Constrain rasterized buffer; avoids QtSvg "buffer too big" warnings.
              implicitSize: 32
              source: Quickshell.iconPath(entryDelegate.modelData.entry.icon, true)

              Gen.MatIcon {
                anchors.centerIn: parent
                color: Dat.Colors.current.on_surface_variant
                font.pointSize: 16
                icon: "apps"
                visible: appIcon.status != Image.Ready
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                Layout.fillWidth: true
                color: Dat.Colors.current.on_surface
                elide: Text.ElideRight
                font.pointSize: 10
                text: entryDelegate.modelData.entry.name
              }

              Text {
                Layout.fillWidth: true
                color: Dat.Colors.current.on_surface_variant
                elide: Text.ElideRight
                font.pointSize: 8
                opacity: 0.8
                text: entryDelegate.modelData.entry.comment ?? ""
                visible: text.length > 0
              }
            }
          }

          Gen.MouseArea {
            id: hoverArea

            hoverEnabled: true
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 12

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mevent => {
              if (mevent.button == Qt.RightButton) {
                Dat.Dock.togglePin(entryDelegate.modelData.entry.id);
                return;
              }
              list.currentIndex = entryDelegate.index;
              root.launchSelected();
            }

            onContainsMouseChanged: {
              if (containsMouse)
                list.currentIndex = entryDelegate.index;
            }
          }

          // pin indicator - right-click toggles it. Pinning moved
          // here from the dock (see Widgets/DockItem.qml)
          Gen.MatIcon {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 8
            color: Dat.Colors.current.primary
            font.pointSize: 11
            icon: "push_pin"
            visible: Dat.Dock.isPinned(entryDelegate.modelData.entry.id)
          }
        }
      }
    }

    Rectangle {
      id: field

      Layout.fillWidth: true
      Layout.preferredHeight: 48
      color: Dat.Colors.current.surface_container
      radius: Dat.Radius.lg

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface_variant
          font.pointSize: 14
          icon: "search"
        }

        TextInput {
          id: input

          Layout.fillWidth: true
          color: Dat.Colors.current.on_surface
          font.pointSize: 11
          selectByMouse: true
          text: Dat.Launcher.query
          verticalAlignment: TextInput.AlignVCenter

          onTextChanged: Dat.Launcher.query = text

          onAccepted: root.launchSelected()

          Keys.onDownPressed: {
            list.incrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }
          Keys.onEscapePressed: event => {
            if (input.text.length > 0) {
              input.text = "";
            } else {
              event.accepted = false;
            }
          }
          Keys.onUpPressed: {
            list.decrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }

          Text {
            anchors.fill: parent
            color: Dat.Colors.current.on_surface_variant
            font.pointSize: 11
            opacity: 0.6
            text: "Search apps..."
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length == 0
          }
        }
      }
    }
  }

  onRequestFocus: input.forceActiveFocus()

  Component.onCompleted: input.forceActiveFocus()
}
