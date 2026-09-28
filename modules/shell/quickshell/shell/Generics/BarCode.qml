import QtQuick

Text {
  id: userText

  property string variant: "39"
  property bool withText: false

  font.weight: Dat.Type.weightBold
  font.family: "Libre Barcode " + variant + ((withText) ? " TEXT" : "")
  renderType: Text.NativeRendering
}
