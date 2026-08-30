import QtQuick
import qs.Data as Dat

Image {
  // when set, resolves this output's wallpaper override (falling back to
  // the global wallSrc); leave empty to always use the global wallSrc
  property string outputName: ""

  antialiasing: true
  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  layer.enabled: true
  retainWhileLoading: true
  smooth: true
  source: Dat.Config.wallpaperFor(outputName)
  // decode at (roughly) the size this actually renders at instead of the
  // source file's native resolution - PreserveAspectCrop just scales/crops
  // it down afterwards regardless, so a wallpaper file with more pixels
  // than the screen buys nothing but a much bigger QImage decode living in
  // RAM. width/height here == the screen's resolution, since this Image
  // is always anchors.fill'd (or explicitly sized) to the layer/output.
  sourceSize.height: height > 0 ? height : 1080
  sourceSize.width: width > 0 ? width : 1920

  onStatusChanged: {
    if (this.status == Image.Error) {
      console.log("[ERROR] Wallpaper source invalid");
      console.log("[INFO] Please disable set wallpaper if not required");
    }
  }
}
