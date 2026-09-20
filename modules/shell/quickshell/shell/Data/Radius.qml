pragma Singleton
import Quickshell

// Single source of truth for corner radii; replaces scattered hardcoded values.
// `full` relies on Qt clamping, so one constant rounds any size.
Singleton {
  id: root

  readonly property int xs: 6
  readonly property int sm: 8
  readonly property int md: 12
  readonly property int lg: 16
  readonly property int xl: 20
  readonly property int xxl: 24

  // steps that only had one or two call sites but are still real,
  // intentional in-between values rather than drift
  readonly property int mdSm: 10
  readonly property int lgSm: 14
  readonly property int xlSm: 18

  // fully rounds (circle or pill), see note above
  readonly property int full: 9999
}
