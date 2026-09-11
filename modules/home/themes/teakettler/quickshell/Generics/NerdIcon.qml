// Nerd Font glyphs on a shared patched typeface; Propo variant for proportional UI.
import QtQuick

Text {
  id: root

  required property string icon

  font.family: "NotoSansM Nerd Font Propo"
  renderType: Text.NativeRendering
  text: root.icon
}
