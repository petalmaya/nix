import QtQuick

Text {
  id: root

  required property string icon

  font.family: "NotoSansM Nerd Font Propo"
  renderType: Text.NativeRendering
  text: root.icon
}
