import QtQuick
import qs.Data as Dat

// Lock/greeter background (desktops are drawn by swaybg now).
Image {
  antialiasing: true
  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  layer.enabled: true
  retainWhileLoading: true
  smooth: true
  source: Dat.Config.lockWallpaper
  // Decode near render size; full-res decodes just waste RAM under PreserveAspectCrop.
  sourceSize.height: height > 0 ? height : 1080
  sourceSize.width: width > 0 ? width : 1920

  onStatusChanged: {
    if (this.status == Image.Error) {
      console.log("[ERROR] Lock wallpaper source invalid: " + source);
    }
  }
}
