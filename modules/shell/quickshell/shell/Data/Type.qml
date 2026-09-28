pragma Singleton
import Quickshell

Singleton {
  id: root

  readonly property int displayLarge: 57
  readonly property int displayMedium: 45
  readonly property int headlineLarge: 32
  readonly property int headlineMedium: 28
  readonly property int headlineSmall: 24
  readonly property int titleLarge: 22
  readonly property int titleMedium: 16
  readonly property int titleSmall: 14
  readonly property int bodyLarge: 16
  readonly property int bodyMedium: 14
  readonly property int bodySmall: 12
  readonly property int labelLarge: 14
  readonly property int labelMedium: 12
  readonly property int labelSmall: 11

  readonly property int weightRegular: Font.Normal
  readonly property int weightMedium: Font.Medium
  readonly property int weightBold: Font.DemiBold
}
