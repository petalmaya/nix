pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.platform

Singleton {
  id: root

  // Cache/config via Qt StandardPaths; see https://doc.qt.io/qt-6/qstandardpaths.html#StandardLocation-enum
  readonly property url cache: `${StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]}/nixtop-shell`
  readonly property url config: `${StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0]}/nixtop-shell`

  function getPath(caller, url: string): string {
    let filename = url.split('/').pop();
    let filepath = root.cache + "/" + filename;
    let script = root.urlToPath(Qt.resolvedUrl("../scripts/cacheImg.sh"));

    let process = cacheImg.incubateObject(root, {
      "command": ["bash", script, url, root.urlToPath(root.cache)],
      "running": true
    });

    process.onStatusChanged = function (status) {
      if (status != Component.Ready) {
        return;
      }

      process.object.exited.connect((eCode, eStat) => {
        if (eCode == 0) {
          caller.source = filepath;
        } else {
          console.log("[ERROR] cacheImg exited with error code: " + eCode);
        }
        process.object.destroy();
      });
    };

    return "";
  }

  function urlToPath(url: url): string {
    return url.toString().replace("file://", "");
  }

  Component {
    id: cacheImg

    Process {
    }
  }
}
