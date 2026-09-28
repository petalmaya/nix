import QtQuick
import qs.Data as Dat

MouseArea {
  id: area

  property real clickOpacity: Dat.Elevation.pressOpacity
  property real hoverOpacity: Dat.Elevation.hoverOpacity
  property color layerColor: Dat.Colors.current.on_surface
  property NumberAnimation layerOpacityAnimation: NumberAnimation {
    duration: Dat.MaterialEasing.standardTime
    easing.bezierCurve: Dat.MaterialEasing.standard
  }
  property int layerRadius: parent?.radius ?? Math.min(parent.width, parent.height)
  property alias layerRect: layer

  anchors.fill: parent
  hoverEnabled: true

  onContainsMouseChanged: layer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
  onContainsPressChanged: layer.opacity = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

  Rectangle {
    id: layer

    anchors.fill: parent
    color: area.layerColor
    opacity: 0
    radius: area.layerRadius

    Behavior on opacity {
      animation: area.layerOpacityAnimation
    }
  }
}
