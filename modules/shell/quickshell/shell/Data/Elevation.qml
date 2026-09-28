pragma Singleton
import Quickshell

Singleton {
  id: root

  readonly property int level0: 0
  readonly property int level1: 1
  readonly property int level2: 3
  readonly property int level3: 6
  readonly property int level4: 8
  readonly property int level5: 12

  readonly property real hoverOpacity: 0.08
  readonly property real pressOpacity: 0.12
  readonly property real focusOpacity: 0.12
  readonly property real dragOpacity: 0.16
  readonly property real scrimOpacity: 0.32
}
