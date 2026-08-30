pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

// Right-hand pane of the fully-expanded notch. Used to be a mascot
// widget (KuruKuru) - this is a compact "now playing" companion
// instead, in the same restrained pill/card language as TopBar and
// the rest of the shell. Tapping the art/title jumps to the full
// MusicView tab (index 3) in CentralSwipable.
Item {
  id: root

  property string outputName: ""
  // some apps register an Mpris interface before any track is actually
  // loaded (phantom playerctld entries, browser tabs, etc) - a player
  // with no title AND no artist AND no art isn't something worth
  // showing, so it's filtered out here rather than falling through to
  // "Unknown track" / "Unknown artist" placeholder text
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
    // only tick while the notch is actually fully expanded (this panel
    // is a permanent, non-Loader child of Primary - the notch's
    // "collapsed" states only toggle expandedPane.visible on an
    // *ancestor*, which doesn't touch this Item's own `visible` or stop
    // its bindings/timers from running). Matches the gating MprisItem
    // already uses for its own timers via Dat.Globals.notchState(),
    // instead of polling in the background for as long as anything is
    // playing regardless of whether the notch is even open.
    running: Dat.Globals.notchState(root.outputName) == "FULLY_EXPANDED" && root.hasPlayer && root.activePlayer.isPlaying

    onTriggered: root.polledPosition = root.activePlayer.position
  }
  onActivePlayerChanged: root.polledPosition = root.hasPlayer ? root.activePlayer.position : 0

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 10

    // top row: notification controls (clear / dnd / idle-inhibit) -
    // functional, kept from the old widget, just no longer sharing
    // space with a mascot
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
