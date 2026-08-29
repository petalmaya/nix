pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt.labs.platform as Labs

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher.mode == "wallpaper". Same self-contained shape
// as LauncherApps.qml - owns its own model/selection, exposes
// requestFocus() - so it drops into Layers/Launcher.qml's Loader.
//
// "This Display" sets that output's desktop background only
// (Dat.Config.wallpapersByOutput); "Lock Screen" sets the one shared
// image used on every monitor (Dat.Config.lockWallpaper). No shared
// default desktop wallpaper - each monitor needs its own pick.
Item {
  id: root

  // pulses when the panel wants the search field focused/refocused
  signal requestFocus

  // the output this launcher instance is open on - always "the screen
  // you're looking at" since Layers/Launcher.qml only shows the
  // matching instance
  readonly property string outputName: Dat.Launcher.outputName
  property bool editingDefault: false
  readonly property string targetOutput: root.editingDefault ? "" : root.outputName
  readonly property string currentSrc: Dat.Config.wallpaperFor(root.targetOutput)

  function pick(path) {
    Dat.Config.setWallpaperFor(root.targetOutput, path);
    Dat.Launcher.hide();
  }

  function pickSelected() {
    if (!list.currentItem)
      return;
    root.pick(Dat.Paths.urlToPath(list.currentItem.fileUrl));
  }

  implicitHeight: col.implicitHeight

  ColumnLayout {
    id: col

    anchors.fill: parent
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: [{
            "label": "This Display",
            "isDefault": false
          }, {
            "label": "Lock Screen",
            "isDefault": true
          }]

        Rectangle {
          id: chip

          required property var modelData

          Layout.preferredHeight: 26
          color: (root.editingDefault == modelData.isDefault) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container
          implicitWidth: chipText.contentWidth + 18
          radius: Dat.Radius.sm

          Text {
            id: chipText

            anchors.centerIn: parent
            color: (chip.modelData.isDefault == root.editingDefault) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
            font.pointSize: 9
            text: chip.modelData.label
          }

          Gen.MouseArea {
            layerColor: chip.modelData.isDefault ? Dat.Colors.current.on_surface : Dat.Colors.current.on_primary
            layerRadius: 8

            onClicked: root.editingDefault = chip.modelData.isDefault
          }
        }
      }

      Item {
        Layout.fillWidth: true
      }

      Rectangle {
        id: matugenToggle

        Layout.preferredHeight: 26
        Layout.preferredWidth: 26
        color: Dat.Config.data.matugenEnabled ? Dat.Colors.current.primary : Dat.Colors.current.surface_container
        radius: Dat.Radius.sm

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Config.data.matugenEnabled ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
          font.pointSize: 12
          icon: "palette"
        }

        Gen.MouseArea {
          layerColor: Dat.Config.data.matugenEnabled ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
          layerRadius: Dat.Radius.sm

          onClicked: Dat.Config.data.matugenEnabled = !Dat.Config.data.matugenEnabled
        }
      }

      Rectangle {
        id: refreshBtn

        Layout.preferredHeight: 26
        Layout.preferredWidth: 26
        color: Dat.Colors.current.surface_container
        radius: Dat.Radius.sm

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Colors.current.on_surface
          font.pointSize: 12
          icon: "refresh"
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 8

          onClicked: folderModel.folder = folderModel.folder
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 150
      clip: true
      color: Dat.Colors.current.surface_container
      radius: Dat.Radius.lg
      visible: folderModel.count > 0

      ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 6
        boundsBehavior: Flickable.StopAtBounds
        // same as LauncherApps.qml - keep a few thumbnails cached
        // just off-screen instead of re-requesting on scroll wobbles
        cacheBuffer: 220
        clip: true
        currentIndex: folderModel.count > 0 ? 0 : -1
        orientation: ListView.Horizontal
        spacing: 8

        model: FolderListModel {
          id: folderModel

          folder: "file://" + Dat.Config.data.wallpaperDir
          nameFilters: root.filtersFor(Dat.Launcher.query)
          showDirs: false
          sortField: FolderListModel.Name

          onCountChanged: list.currentIndex = folderModel.count > 0 ? 0 : -1
        }

        delegate: Item {
          id: thumbDelegate

          required property url fileUrl
          required property string fileName
          required property int index

          readonly property bool isApplied: root.currentSrc == Dat.Paths.urlToPath(thumbDelegate.fileUrl)
          readonly property bool isSelected: list.currentIndex == thumbDelegate.index

          height: list.height
          width: 128

          Rectangle {
            id: frame

            anchors.fill: parent
            anchors.bottomMargin: 20
            clip: true
            color: Dat.Colors.current.surface_container_high
            radius: Dat.Radius.mdSm

            Image {
              id: thumbImg

              anchors.fill: parent
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              smooth: true
              source: thumbDelegate.fileUrl
              sourceSize.height: 116
              sourceSize.width: 116
            }

            // separate overlay drawn on top of the Image, since a
            // border on the Image's own parent got painted over -
            // a shader-based rounded mask was tried instead and broke
            // thumbnail loading, reverted
            Rectangle {
              id: selectionRing

              anchors.fill: parent
              border.color: Dat.Colors.current.primary
              border.width: thumbDelegate.isSelected ? 3 : (thumbDelegate.isApplied ? 2 : 0)
              color: "transparent"
              radius: Dat.Radius.mdSm

              Behavior on border.width {
                NumberAnimation {
                  duration: Dat.MaterialEasing.standardTime
                  easing.bezierCurve: Dat.MaterialEasing.standard
                }
              }
            }

            Gen.MouseArea {
              layerColor: Dat.Colors.current.primary
              layerRadius: 10

              onClicked: {
                list.currentIndex = thumbDelegate.index;
                root.pick(Dat.Paths.urlToPath(thumbDelegate.fileUrl));
              }
            }
          }

          Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 2
            color: Dat.Colors.current.on_surface_variant
            elide: Text.ElideMiddle
            font.pointSize: 7
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.8
            text: thumbDelegate.fileName
          }
        }
      }
    }

    Text {
      Layout.fillWidth: true
      color: Dat.Colors.current.on_surface
      font.pointSize: 9
      horizontalAlignment: Text.AlignHCenter
      opacity: 0.7
      text: (Dat.Config.data.wallpaperDir == "" || folderModel.count > 0) ? "" : (Dat.Launcher.query == "" ? "No wallpapers found in this folder" : "No wallpapers match \u201c" + Dat.Launcher.query + "\u201d")
      visible: text.length > 0
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

          onAccepted: root.pickSelected()

          // TextInput eats Left/Right for cursor movement by default
          // (Keys.AfterItem runs after item key handling) - BeforeItem
          // makes onLeftPressed/onRightPressed below run first instead
          Keys.priority: Keys.BeforeItem

          Keys.onEscapePressed: event => {
            if (input.text.length > 0) {
              input.text = "";
            } else {
              event.accepted = false;
            }
          }
          // Left/Right move the row selection instead of the text
          // cursor, same idea as LauncherApps' Up/Down override
          Keys.onLeftPressed: {
            list.decrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }
          Keys.onRightPressed: {
            list.incrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }

          Text {
            anchors.fill: parent
            color: Dat.Colors.current.on_surface_variant
            font.pointSize: 11
            opacity: 0.6
            text: "Search wallpapers..."
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length == 0
          }
        }

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface_variant
          font.pointSize: 13
          icon: "close"
          opacity: clearArea.containsMouse ? 1 : 0.6
          visible: input.text.length > 0

          MouseArea {
            id: clearArea

            anchors.margins: -6
            anchors.fill: parent
            hoverEnabled: true

            onClicked: input.text = ""
          }
        }
      }
    }
  }

  // FolderListModel only filters by glob, so wrap the query in *...*
  // per extension for live-search behavior. Skips animated formats
  // (gif/mp4) for now.
  function filtersFor(query) {
    const exts = ["png", "jpg", "jpeg", "webp", "bmp"];
    const q = query.trim();
    if (q == "")
      return exts.map(e => "*." + e);
    return exts.map(e => "*" + q + "*." + e);
  }

  onRequestFocus: input.forceActiveFocus()

  Component.onCompleted: input.forceActiveFocus()
}
