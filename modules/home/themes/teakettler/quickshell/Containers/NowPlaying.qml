pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Right-hand pane of the expanded notch; tapping art/title jumps to MusicView (tab 3).
Item {
  id: root

  property string outputName: ""
  // Filter out phantom Mpris entries with no title, artist, or art.
  function hasRealTrack(p) {
    return !!(p.trackTitle || p.trackArtist || p.trackArtUrl);
  }
  readonly property var activePlayer: {
    const players = Mpris.players.values.filter(hasRealTrack);
    if (players.length === 0)
      return null;
    // prefer whichever player is actually playing, else just the first
    for (const p of players) {
      if (p.isPlaying)
        return p;
    }
    return players[0];
  }
  readonly property bool hasPlayer: root.activePlayer !== null

  // position doesn't update reactively on its own - poll it while a
  // track is actually playing, same approach as MprisItem's rotateTimer
  property real polledPosition: 0

  Timer {
    interval: 1000
    repeat: true
    // Permanent Primary child, so gate polling on notch state; matches MprisItem gating.
    running: Dat.Globals.notchState(root.outputName) == "FULLY_EXPANDED" && root.hasPlayer && root.activePlayer.isPlaying

    onTriggered: root.polledPosition = root.activePlayer.position
  }
  onActivePlayerChanged: root.polledPosition = root.hasPlayer ? root.activePlayer.position : 0

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 10

    // Notification controls row.
    RowLayout {
      Layout.fillWidth: true

      Item {
        Layout.fillWidth: true
      }

      Wid.NotifDots {
        color: Dat.Colors.current.surface_container
        implicitHeight: 32
        radius: Dat.Radius.full
      }
    }

    Item {
      Layout.fillHeight: true
      Layout.fillWidth: true

      // idle state - no player at all
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 6
        visible: !root.hasPlayer

        Gen.MatIcon {
          Layout.alignment: Qt.AlignHCenter
          color: Dat.Colors.current.on_surface_variant
          font.pixelSize: 32
          icon: "music_off"
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          color: Dat.Colors.current.on_surface_variant
          text: "Nothing playing"
        }
      }

      // now-playing card
      Rectangle {
        anchors.fill: parent
        color: Dat.Colors.current.surface_container_low
        radius: Dat.Radius.xl
        visible: root.hasPlayer

        Behavior on color {
          ColorAnimation {
            duration: Dat.MaterialEasing.standardTime
          }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
              id: artFrame

              Layout.preferredHeight: 64
              Layout.preferredWidth: 64
              color: Dat.Colors.current.surface_container_high
              radius: Dat.Radius.lg

              Image {
                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                smooth: true
                source: root.hasPlayer ? (root.activePlayer.trackArtUrl ?? "") : ""
              }

              Gen.MouseArea {
                anchors.fill: parent
                layerRadius: artFrame.radius

                onClicked: {
                  Dat.Globals.setSwipeIndex(root.outputName, 3);
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                Layout.fillWidth: true
                color: Dat.Colors.current.on_surface
                elide: Text.ElideRight
                font.bold: true
                font.pointSize: 11
                text: root.hasPlayer ? (root.activePlayer.trackTitle || "Unknown track") : ""
              }

              Text {
                Layout.fillWidth: true
                color: Dat.Colors.current.on_surface_variant
                elide: Text.ElideRight
                font.pointSize: 9
                text: root.hasPlayer ? (root.activePlayer.trackArtist || "Unknown artist") : ""
              }
            }
          }

          // progress bar
          Rectangle {
            id: progressTrack

            readonly property real fraction: (root.hasPlayer && root.activePlayer.length > 0) ? Math.min(1, root.polledPosition / root.activePlayer.length) : 0

            Layout.fillWidth: true
            Layout.preferredHeight: 4
            color: Dat.Colors.current.surface_container_high
            radius: Dat.Radius.full

            Rectangle {
              color: Dat.Colors.current.primary
              height: parent.height
              radius: parent.radius
              width: parent.width * parent.fraction

              Behavior on width {
                NumberAnimation {
                  duration: Dat.MaterialEasing.standardTime
                  easing.bezierCurve: Dat.MaterialEasing.standard
                }
              }
            }
          }

          // transport controls
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Gen.MatIcon {
              color: Dat.Colors.current.on_surface_variant
              font.pixelSize: 22
              icon: "skip_previous"

              Gen.MouseArea {
                anchors.fill: parent
                layerRadius: Dat.Radius.full

                onClicked: root.activePlayer?.previous()
              }
            }

            Gen.MatIcon {
              color: Dat.Colors.current.on_surface
              fill: 1
              font.pixelSize: 30
              icon: (root.hasPlayer && root.activePlayer.isPlaying) ? "pause_circle" : "play_circle"

              Gen.MouseArea {
                anchors.fill: parent
                layerRadius: Dat.Radius.full

                onClicked: root.activePlayer?.togglePlaying()
              }
            }

            Gen.MatIcon {
              color: Dat.Colors.current.on_surface_variant
              font.pixelSize: 22
              icon: "skip_next"

              Gen.MouseArea {
                anchors.fill: parent
                layerRadius: Dat.Radius.full

                onClicked: root.activePlayer?.next()
              }
            }
          }
        }
      }
    }
  }
}
