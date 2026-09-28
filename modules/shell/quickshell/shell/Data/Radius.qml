pragma Singleton
import Quickshell

// Qt clamps `full` to a pill/circle on any size.
Singleton {
  id: root

  readonly property int xs: 4
  readonly property int sm: 8
  readonly property int md: 12
  readonly property int lg: 16
  readonly property int xl: 28
  readonly property int mdSm: 10
  readonly property int lgSm: 14
  readonly property int xlSm: 18
  readonly property int full: 9999
}
